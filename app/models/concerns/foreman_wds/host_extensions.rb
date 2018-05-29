module ForemanWds
  module HostExtensions
    def self.prepended(base)
      base.class_eval do
        after_build :ensure_wds_client
        before_provision :remove_wds_client
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
      return super + [:wds] if compute_resource && (os.nil? || os.family == 'Windows')
      super
    end

    def bare_metal_capabilities
      return super + [:wds] if os.nil? || os.family == 'Windows'
      super
    end

    def can_be_built?
      super || (wds? && !build?)
    end

    def wds_build?
      provision_method == 'wds'
    end

    def wds?
      managed? && wds_build? && SETTINGS[:unattended]
    end

    def ensure_wds_facet
      wds_facet || build_wds_facet
    end

    def unattend_pass(password, suffix = nil)
      if suffix.nil?
        suffix = password
        password = Base64.decode64(root_pass)
      end
      Base64.encode64(Encoding::Converter.new('UTF-8', 'UTF-16LE', undef: nil).convert(password + suffix)).delete!("\n")
    end

    private

    def ensure_wds_client
      raise NotImplementedError, 'Not implemented yet'
      return unless wds?

      wds_server.ensure_unattend(self)
      client = wds_server.client(self) || wds_server.create_client(self)

      Rails.logger.info client
      true
    rescue ScriptError, StandardError => ex
      Rails.logger.error "Failed to ensure WDS client, #{ex}"
      # false
    end

    def remove_wds_client
      raise NotImplementedError, 'Not implemented yet'
      return unless wds?

      client = wds_server.client(self)
      return unless client

      wds_server.delete_client(client)
      true
    rescue ScriptError, StandardError => ex
      Rails.logger.error "Failed to remove WDS client, #{ex}"
      # false
    end
  end
end

class ::Host::Managed::Jail < Safemode::Jail
  allow :unattend_pass, :wds_facet, :wds_server, :wds_install_image_file, :wds_install_image_group, :wds_install_image_name
end
