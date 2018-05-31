module ForemanWds
  class WdsFacet < ApplicationRecord
    class Jail < Safemode::Jail
      allow :boot_image_file, :boot_image_name, :install_image_file, :install_image_group, :install_image_name
    end

    include Facets::Base

    belongs_to :wds_server,
               class_name: '::WdsServer',
               inverse_of: :wds_facets

    validates_lengths_from_database

    validates :host, presence: true, allow_blank: false

    validates :install_image_name, presence: true, allow_blank: false

    def boot_image
      return nil unless wds_server
      @boot_image ||= if boot_image_name
                        wds_server.boot_image(boot_image_name)
                      else
                        wds_server.boot_images.first
                      end
    end

    def boot_image_file
      return nil unless boot_image
      @boot_image_file ||= boot_image.file_name
    end

    def install_image
      return nil unless wds_server
      @install_image ||= wds_server.install_image(install_image_name)
    end

    def install_image_file
      return nil unless install_image
      @install_image_file ||= install_image.file_name
    end

    def install_image_group
      return nil unless install_image
      @install_image_group ||= install_image.image_group
    end
  end
end
