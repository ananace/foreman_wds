module ForemanWds
  class WdsFacet < ApplicationRecord
    include Facets::Base

    belongs_to :wds_server,
               class_name: '::ForemanWds::WdsServer',
               inverse_of: :wds_facets

    validates_lengths_from_database

    validates :host, presence: true, allow_blank: false

    def boot_image
      wds_server.boot_image(boot_image_name)
    end

    def install_image
      wds_server.install_image(install_image_name)
    end
  end
end
