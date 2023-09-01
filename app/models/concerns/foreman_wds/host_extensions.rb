# frozen_string_literal: true

module ForemanWds
  module HostExtensions
    def self.prepended(base)
      base.class_eval do
        after_build :ensure_wds_client
        after_build :ensure_wds_boot
        before_provision :remove_wds_client

        has_one :wds_facet,
                class_name: '::ForemanWds::WdsFacet',
                foreign_key: :host_id,
                inverse_of: :host,
                dependent: :destroy
      end
    end

    delegate :wds_server, to: :wds_facet

    def wds_boot_image
      ensure_wds_facet.boot_image
    end

    def wds_boot_image_name
      ensure_wds_facet.boot_image_name
    end

    def wds_install_image
      ensure_wds_facet.install_image
    end

    def wds_install_image_file
      ensure_wds_facet.install_image_file
    end

    def wds_install_image_group
      ensure_wds_facet.install_image_group
    end

    def wds_install_image_name
      ensure_wds_facet.install_image_name
    end

    def capabilities
      return [:wds] if wds_build?
      return super + [:wds] if compute_resource && (os.nil? || os.family == 'Windows')

      super
    end

    def bare_metal_capabilities
      return [:wds] if wds_build?
      return super + [:wds] if os.nil? || os.family == 'Windows'

      super
    end

    def can_be_built?
      super || (managed? && SETTINGS[:unattended] && wds? && !build?)
    end

    def wds_build?
      self[:provision_method] == 'wds'
    end

    def pxe_build?
      return true if wds_build?

      super
    end

    def wds?
      managed? && wds_build? && SETTINGS[:unattended]
    end

    def ensure_wds_facet
      wds_facet || build_wds_facet
    end

    def unattend_arch
      WdsServer.wdsify_processor_architecture(architecture)
    end

    def unattend_pass(password, suffix = nil)
      if suffix.nil?
        suffix = password
        password = Base64.decode64(root_pass)
      end
      Base64.encode64(Encoding::Converter.new('UTF-8', 'UTF-16LE', undef: nil).convert(password + suffix)).delete!("\n")
    end

    private

    def ensure_wds_boot
      return unless wds?

      parameters.where(name: 'wds-specifictemplate').each(&:destroy)
      Rails.logger.info 'Ensuring WDS boot'
    rescue StandardError => ex
      Rails.logger.error "Failed to ensure WDS boot, #{ex}"
    end

    def ensure_wds_client
      return unless wds?

      raise NotImplementedError, 'Not implemented yet'
      client = wds_server.ensure_client(self)

      Rails.logger.info client
      true
    rescue ScriptError, StandardError => ex
      Rails.logger.error "Failed to ensure WDS client, #{ex}"
      # false
    end

    def remove_wds_client
      return unless wds?

      raise NotImplementedError, 'Not implemented yet'
      wds_server.delete_client(self)
      true
    rescue ScriptError, StandardError => ex
      Rails.logger.error "Failed to remove WDS client, #{ex}"
      # false
    end
  end
end

class ::Host::Managed::Jail < Safemode::Jail
  allow :unattend_arch, :unattend_pass, :wds_build?, :wds_facet, :wds_server, :wds_install_image_file, :wds_install_image_group, :wds_install_image_name
end
