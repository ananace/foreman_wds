class WdsServer < ApplicationRecord
  class Jail < Safemode::Jail
    allow :name, :shortname
  end

  include Encryptable
  extend FriendlyId
  friendly_id :name
  include Parameterizable::ByIdName
  encrypts :password

  validates_lengths_from_database

  audited except: [:password]
  has_associated_audits

  before_destroy EnsureNotUsedBy.new(:hosts)

  has_many :wds_facets,
           class_name: '::ForemanWds::WdsFacet',
           dependent: :nullify,
           inverse_of: :wds_server

  has_many :hosts,
           class_name: '::Host::Managed',
           dependent: :nullify,
           inverse_of: :wds_server,
           through: :wds_facets

  validates :name, presence: true, uniqueness: true
  validates :url, presence: true
  validates :user, presence: true
  validates :password, presence: true

  scoped_search on: :name, complete_value: true
  default_scope -> { order('wds_servers.name') }

  def boot_image(name)
    images(:boot, name).first
  end

  def install_image(name)
    images(:install, name).first
  end

  def clients
    objects = connection.run_wql('SELECT * FROM MSFT_WdsClient')[:msft_wdsclient] rescue nil
    objects = nil if objects.empty?
    objects ||= begin
      data = connection.shell(:powershell) do |s|
        s.run('Get-WdsClient | ConvertTo-Json -Compress')
      end.stdout
      data = '[]' if data.empty?

      underscore_result([JSON.parse(data)].flatten)
    end

    objects
  end

  def client(host)
    clients.find do |c|
      [host.mac.upcase.tr(':', '-'), host.name].include?(c[:device_id]) || [host.name, host.shortname].include?(c[:device_name])
    end
  end

  def boot_images
    cache.cache(:boot_images) do
      images(:boot)
    end.each { |i| i.wds_server = self }
  end

  def install_images
    cache.cache(:install_images) do
      images(:install)
    end.each { |i| i.wds_server = self }
  end

  def create_client(host)
    raise NotImplementedError, 'Not finished yet'
    ensure_unattend(host)

    connection.shell(:powershell) do |sh|
      sh.run("New-WdsClient -DeviceID '#{host.mac.upcase.delete ':'}' -DeviceName '#{host.name}' -WdsClientUnattend '#{unattend_file(host)}' -BootImagePath 'boot\\#{wdsify_architecture(host.architecture)}\\images\\#{(host.wds_boot_image || boot_images.first).file_name}' -PxePromptPolicy 'NoPrompt'")
    end
  end

  def delete_client(host)
    raise NotImplementedError, 'Not finished yet'
    delete_unattend(host)

    connection.shell(:powershell) do |sh|
      sh.run("Remove-WdsClient -DeviceID '#{host.mac.upcase.delete ':'}'")
    end
  end

  def all_images
    boot_images + install_images
  end

  def timezone
    cache.cache(:timezone) do
      connection.run_wql('SELECT Bias FROM Win32_TimeZone')[:xml_fragment].first[:bias].to_i * 60
    end
  end

  def shortname
    cache.cache(:shortname) do
      connection.run_wql('SELECT Name FROM Win32_ComputerSystem')[:xml_fragment].first[:name]
    end
  end

  def next_server_ip
    IPSocket.getaddress URI(url).host
  rescue SocketError
    ::Rails.logger.info "Failed to look up IP of WDS server #{name}"
    nil
  end

  def self.bootfile_path(architecture_name, loader = :bios, boot_type = :pxe)
    file_name = nil
    if boot_type == :local
      file_name = 'bootmgfw.efi' if loader == :uefi
      file_name = 'abortpxe.com' if loader == :bios
    elsif boot_type == :pxe
      file_name = 'wdsmgfw.efi' if loader == :uefi
      file_name = 'wdsnbp.com' if loader == :bios
    end
    raise ArgumentError, 'Invalid loader or boot type provided' if file_name.nil?

    "boot\\\\#{architecture_name}\\\\#{file_name}"
  end

  def self.wdsify_architecture(architecture)
    wds_arch = ForemanWds::WdsImage::WDS_IMAGE_ARCHES.find_index { |arch| arch =~ architecture.name }
    ForemanWds::WdsImage::WDS_ARCH_NAMES[wds_arch]
  end

  def self.wdsify_processor_architecture(architecture)
    wds_arch = ForemanWds::WdsImage::WDS_IMAGE_ARCHES.find_index { |arch| arch =~ architecture.name }
    ForemanWds::WdsImage::WDS_ARCH_NAMES[wds_arch]
  end

  def test_connection
    connection.run_wql('SELECT * FROM Win32_UTCTime').key? :win32_utc_time
  rescue StandardError
    false
  end

  def refresh_cache
    cache.refresh
  end

  private

  def unattend_path
    cache.cache(:unattend_path) do
      JSON.parse(connection.shell(:powershell) do |sh|
        sh.run('Get-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\WDSServer\Providers\WDSTFTP -Name RootFolder | select RootFolder | ConvertTo-Json -Compress')
      end, symbolize_names: true)[:RootFolder]
    end
  end

  def unattend_file(host)
    "#{unattend_path}\\#{host.mac.tr ':', '_'}.xml"
  end

  def target_image_for(host)
    source_image = host.wds_install_image
    ForemanWds::WdsInstallImage.new(
      wds_server: self,
      file_name: "install-#{host.mac.tr ':', '_'}.wim",
      image_group: SETTINGS[:wds_unattend_group] || source_image.image_group,
      image_name: "#{source_image.image_name} (specialized for #{host.name}/#{host.mac})"
    )
  end

  def ensure_unattend(host)
    raise NotImplementedException, 'TODO: Not implemented yet'
    connection.shell(:powershell) do |sh|
      target_image = target_image_for(host)
      # TODO: render template, send as heredoc
      # sh.run("$unattend_render = @'\n#{unattend_template}\n'@")
      # sh.run("New-Item -Path '#{unattend_file(host)}' -ItemType 'file' -Value $unattend_render")
      if SETTINGS[:wds_unattend_group]
        # New-WdsInstallImageGroup -Name #{SETTINGS[:wds_unattend_group]}
        # Export-WdsInstallImage -ImageGroup <Group> ...
        # Import-WdsInstallImage -ImageGroup #{SETTINGS[:wds_unattend_group]} -UnattendFile '#{unattend_file(host)}' -OverwriteUnattend ...
      else
        source_image = host.wds_facet.install_image

        sh.run("Copy-WdsInstallImage -ImageGroup '#{source_image.image_group}' -FileName '#{source_image.file_name}' -ImageName '#{source_image.image_name}' -NewFileName '#{target_image.file_name}' -NewImageName '#{target_image.image_name}'")
        sh.run("Set-WdsInstallImage -ImageGroup '#{target_image.image_group}' -FileName '#{target_image.file_name}' -ImageName '#{target_image.image_name}' -DisplayOrder 99999 -UnattendFile '#{unattend_file(host)}' -OverwriteUnattend")
      end
    end
  end

  def delete_unattend(host)
    image = target_image_for(host)

    connection.shell(:powershell) do |sh|
      sh.run("Remove-WdsInstallImage -ImageGroup '#{image.image_group}' -ImageName '#{image.image_name}' -FileName '#{image.file_name}'")
      sh.run("Remove-Item -Path '#{unattend_file(host)}'")
    end.errcode.zero?
  end


  def images(type, name = nil)
    raise ArgumentError, 'Type must be :boot or :install' unless %i[boot install].include? type

    begin
      objects = connection.run_wql("SELECT * FROM MSFT_Wds#{type.to_s.capitalize}Image#{" WHERE Name=\"#{name}\"" if name}")["msft_wds#{type}image".to_sym]
      objects = nil if objects.empty?
    rescue StandardError => e
      ::Rails.logger.debug "WQL image query failed with #{e.class}: #{e}"
    end

    unless objects
      begin
        result = connection.shell(:powershell) do |s|
          s.run("Get-WDS#{type.to_s.capitalize}Image #{"-ImageName '#{name.sub("'", "`'")}'" if name} | ConvertTo-Json -Compress")
        end

        objects = underscore_result([JSON.parse(result.stdout)].flatten)
      rescue JSON::ParserError => e
        ::Rails.logger.error "#{e.class}: #{e}\n#{result}"
        raise e
      end
    end

    objects.map do |obj|
      ForemanWds.const_get("Wds#{type.to_s.capitalize}Image").new obj.merge(wds_server: self)
    end
  end

  def underscore_result(result)
    case result
    when Array
      result.map { |v| underscore_result(v) }
    when Hash
      Hash[result.map { |k, v| [k.to_s.underscore.to_sym, underscore_result(v)] }]
    else
      result
    end
  end

  def cache
    @cache ||= WdsImageCache.new(self)
  end

  def connection
    require 'winrm'

    @connection ||= WinRM::Connection.new endpoint: url, transport: :negotiate, user: user, password: password
  end
end
