class WdsServer < ApplicationRecord::Base
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

  scoped_search on: :name, complete_value: true
  default_scope -> { order('wds_server.name') }
end
