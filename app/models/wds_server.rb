require 'winrm'

class WdsServer < ActiveRecord::Base
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
    images(:boot)
  end

  def install_images
    images(:install)
  end

  def test_connection
    client.run_wql('SELECT * FROM Win32_UTCTime').key? :win32_utc_time
  rescue StandardError
    false
  end

  private

  def images(type, name = nil)
    raise ArgumentError, 'Type must be :boot or :install' unless %i[boot install].include? type

    objects = JSON.parse(client.shell(:powershell) do |s|
      s.run("Get-WDS#{type.to_s.capitalize}Image #{"-ImageName '#{name.sub("'", "`'")}'" if name} | ConvertTo-Json")
    end.stdout, symbolize_names: true)

    objects.map do |obj|
      ForemanWds.const_get("Wds#{type.to_s.capitalize}Image").new obj.merge(wds_server: self)
    end
  end

  def client
    @client ||= WinRM::Connection.new endpoint: url, transport: :negotiate, user: user, password: password
  end
end
