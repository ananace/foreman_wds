# frozen_string_literal: true

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
    objects = run_wql('SELECT * FROM MSFT_WdsClient', on_error: {})[:msft_wdsclient]
    objects = nil if objects&.empty?
    objects ||= begin
      clients = run_pwsh('Get-WdsClient').stdout
      clients = '[]' if clients.empty?
      underscore_result([JSON.parse(clients)].flatten)
    end

    objects
  end

  def client(host)
    device_ids = [host.mac.upcase.tr(':', '-'), host.name]
    device_names = [host.name, host.shortname]
    clients.find do |c|
      device_ids.include?(c[:device_id]) || device_names.include?(c[:device_name])
    end
  end

  def boot_images
    cache.cache(:boot_images) do
      images(:boot).each { |i| i.wds_server = self }
    end
  end

  def install_images
    cache.cache(:install_images) do
      images(:install).each { |i| i.wds_server = self }
    end
  end

  def create_client(host)
    raise NotImplementedError, 'Not finished yet'
    ensure_unattend(host)

    run_pwsh [
      'New-WdsClient',
      "-DeviceID '#{host.mac.upcase.delete ':'}'",
      "-DeviceName '#{host.name}'",
      "-WdsClientUnattend '#{unattend_file(host)}'",
      '-BootImagePath',
      [
        'boot',
        wdsify_architecture(host.architecture),
        'images',
        (host.wds_boot_image || boot_images.first).file_name
      ].join('\\').then { |path| "'#{path}'" },
      "-PxePromptPolicy 'NoPrompt'"
    ].join(' ')
  end

  def delete_client(host)
    raise NotImplementedError, 'Not finished yet'
    delete_unattend(host)

    run_pwsh("Remove-WdsClient -DeviceID '#{host.mac.upcase.delete ':'}'", json: false)
  end

  def all_images
    boot_images + install_images
  end

  def timezone
    cache.cache(:timezone) do
      run_wql('SELECT Bias FROM Win32_TimeZone')[:xml_fragment].first[:bias].to_i * 60
    end
  end

  def shortname
    cache.cache(:shortname) do
      run_wql('SELECT Name FROM Win32_ComputerSystem')[:xml_fragment].first[:name]
    end
  end

  def next_server_name
    URI(url).host
  end

  def next_server_ip
    res = Resolv::DNS.open { |dns| dns.getaddresses(next_server_name) }.select { |addr| addr.is_a? Resolv::IPv4 }.first
    return res.to_s if res

    IPSocket.getaddress URI(url).host
  rescue StandardError => e
    ::Rails.logger.info "Failed to look up IP of WDS server #{name}. #{e.class}: #{e}"
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
    run_wql('SELECT * FROM Win32_UTCTime', on_error: {}).key? :win32_utc_time
  end

  def refresh_cache
    cache.refresh
  end

  private

  def unattend_path
    cache.cache(:unattend_path) do
      JSON.parse(
        run_pwsh(
          [
            'Get-ItemProperty',
            '  -Path HKLM:\SYSTEM\CurrentControlSet\Services\WDSServer\Providers\WDSTFTP',
            '  -Name RootFolder',
            '| select RootFolder'
          ].map(&:strip).join(' ')
        ),
        symbolize_names: true
      )[:RootFolder]
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
    iface = host&.provision_interface
    raise 'No provisioning interface available' unless iface

    raise NotImplementedException, 'TODO: Not implemented yet'
    raise NotImplementedException, 'TODO: Not implemented yet' if SETTINGS[:wds_unattend_group]

    # TODO: render template, send as heredoc
    template = host.operatingsystem.provisioning_templates.find { |t| t.template_kind.name == 'wds_unattend' }
    unless template
      logger.warn 'No WDS Unattend template specified, falling back to provision template'
      template ||= host.operatingsystem.provisioning_templates.find { |t| t.template_kind.name == 'provision' }
    end
    raise 'No provisioning template available' unless template

    template_data = host.render_template template: template

    file_path = unattend_file(host)
    script = []
    script << "$unattend_render = @'\n#{template_data}\n'@"
    script << "New-Item -Path '#{file_path}' -ItemType 'file' -Value $unattend_render"

    source_image = host.wds_facet.install_image
    target_image = target_image_for(host)

    if SETTINGS[:wds_unattend_group]
      # New-WdsInstallImageGroup -Name #{SETTINGS[:wds_unattend_group]}
      # Export-WdsInstallImage -ImageGroup <Group> ...
      # Import-WdsInstallImage -ImageGroup #{SETTINGS[:wds_unattend_group]} -UnattendFile '#{file_path}' -OverwriteUnattend ...
    else
      script << [
        'Copy-WdsInstallImage',
        "  -ImageGroup '#{source_image.image_group}'",
        "  -FileName '#{source_image.file_name}'",
        "  -ImageName '#{source_image.image_name}'",
        "  -NewFileName '#{target_image.file_name}'",
        "  -NewImageName '#{target_image.image_name}'"
      ].map(&:strip).join(' ')
      script << [
        'Set-WdsInstallImage',
        "  -ImageGroup '#{target_image.image_group}'",
        "  -FileName '#{target_image.file_name}'",
        "  -ImageName '#{target_image.image_name}'",
        '  -DisplayOrder 99999',
        "  -UnattendFile '#{file_path}'",
        '  -OverwriteUnattend'
      ].map(&:strip).join(' ')
    end

    run_pwsh script.join("\n"), json: false
  end

  def delete_unattend(host)
    image = target_image_for(host)

    command = []
    command << [
      'Remove-WdsInstallImage',
      "  -ImageGroup '#{image.image_group}'",
      "  -ImageName '#{image.image_name}'",
      "  -FileName '#{image.file_name}'"
    ].map(&:strip).join(' ')
    command << "Remove-Item -Path '#{unattend_file(host)}'"
    run_pwsh(command.join("\n"), json: false).errcode.zero?
  end

  def ensure_client(_host)
    raise NotImplementedException, 'TODO: Not implemented yet'
  end

  def delete_client(_host)
    raise NotImplementedException, 'TODO: Not implemented yet'
  end

  def images(type, name = nil)
    raise ArgumentError, 'Type must be :boot or :install' unless %i[boot install].include? type

    objects = run_wql("SELECT * FROM MSFT_Wds#{type.to_s.capitalize}Image#{" WHERE Name=\"#{name}\"" if name}", on_error: {})["msft_wds#{type}image".to_sym]
    objects = nil if objects.empty?

    unless objects
      result = run_pwsh "Get-WDS#{type.to_s.capitalize}Image#{" -ImageName '#{name.sub("'", "`'")}'" if name}"

      begin
        objects = underscore_result([JSON.parse(result.stdout)].flatten)
      rescue JSON::ParserError => e
        ::Rails.logger.error "Failed to parse images - #{e.class}: #{e}, the data was;\n#{result.inspect}"
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
      result.to_h { |k, v| [k.to_s.underscore.to_sym, underscore_result(v)] }
    else
      result
    end
  end

  def run_pwsh(command, json: true)
    command = [command] unless command.is_a? Array
    command << '| ConvertTo-Json -Compress' if json
    connection.shell(:powershell) do |s|
      s.run command.join(' ')
    end
  end

  def run_wql(wql, on_error: :raise)
    connection.run_wql(wql)
  rescue StandardError
    raise if on_error == :raise

    on_error
  end

  def cache
    @cache ||= WdsImageCache.new(self)
  end

  def connection
    require 'winrm'

    @connection ||= WinRM::Connection.new endpoint: url, transport: :negotiate, user: user, password: password
  end
end
