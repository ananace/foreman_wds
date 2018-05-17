require 'winrm'

class WdsServer < ApplicationRecord
  include Encryptable
  extend FriendlyId
  friendly_id :name
  include Parameterizable::ByIdName
  encrypts :password

  validates_lengths_from_database

  audited except: [:password]
  has_associated_audits

  before_destroy EnsureNotUsedBy.new(:hosts)

  has_many_hosts dependent: :nullify

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

  def all_images
    boot_images + install_images
  end

  def timezone
    cache.cache(:timezone) do
      client.run_wql('SELECT Bias FROM Win32_TimeZone')[:xml_fragment].first[:bias].to_i * 60
    end
  end

  def next_server_ip
    IPSocket.getaddress URI(url).host
  rescue SocketError
    ::Rails.logger.info "Failed to look up IP of WDS server #{name}"
    nil
  end

  def bootfile_path(architecture_name, loader = :bios, boot_type = :pxe)
    file_name = nil
    if boot_type == :local
      file_name = 'bootmgfw.efi' if loader == :uefi
      file_name = 'abortpxe.com' if loader == :bios
    elsif boot_type == :pxe
      file_name = 'wdsmgfw.efi' if loader == :uefi
      file_name = 'wdsnbp.com' if loader == :bio
    end
    raise ArgumentError, 'Invalid loader or boot type provided' if file_name.nil?

    "boot\\#{architecture_name}\\#{file_name}"
  end

  def test_connection
    client.run_wql('SELECT * FROM Win32_UTCTime').key? :win32_utc_time
  rescue StandardError
    false
  end

  def refresh_cache
    cache.refresh
  end

  private

  def images(type, name = nil)
    raise ArgumentError, 'Type must be :boot or :install' unless %i[boot install].include? type

    objects = client.run_wql("SELECT * FROM MSFT_Wds#{type.to_s.capitalize}Image#{" WHERE ImageName=\"#{name}\"" if name}")["msft_wds#{type}image".to_sym]
    objects = nil if objects.empty?
    objects ||= [JSON.parse(client.shell(:powershell) do |s|
      s.run("Get-WDS#{type.to_s.capitalize}Image #{"-ImageName '#{name.sub("'", "`'")}'" if name} | ConvertTo-Json")
    end.stdout, symbolize_names: true)].flatten

    objects.map do |obj|
      ForemanWds.const_get("Wds#{type.to_s.capitalize}Image").new obj.merge(wds_server: self)
    end
  end

  def cache
    @cache ||= WdsImageCache.new(self)
  end

  def client
    @client ||= WinRM::Connection.new endpoint: url, transport: :negotiate, user: user, password: password
  end
end
