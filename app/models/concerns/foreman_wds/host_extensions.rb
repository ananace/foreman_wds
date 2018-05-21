module ForemanWds
  module HostExtensions
    def self.prepended(base)
      base.class_eval do
        before_provision :orchestrate_wds_client
      end
    end

    attr_accessor :wds_server_id

    def wds_server
      return wds_facet.wds_server if wds_facet
      WdsServer.find(@wds_server_id)
    end

    def wds_boot_image
      ensure_wds_facet.boot_image
    end

    def wds_boot_image_name
      ensure_wds_facet.boot_image_name
    end

    def wds_install_image
      ensure_wds_facet.install_image
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

    def wds_build?
      provision_method == 'wds'
    end

    def wds?
      managed? && wds_build? && SETTINGS[:unattended]
    end

    def ensure_wds_facet
      wds_facet || build_wds_facet
    end

    def unattend_pass(suffix = '')
      Base64.encode64(Encoding::Converter.new('UTF-8', 'UTF-16LE', undef: nil).convert(Base64.decode64(root_pass) + suffix)).delete!("\n")
    end

    private

    def orchestrate_wds_client
      return unless wds?

      client = wds_server.client(self) || wds_server.create_client(self)

      Rails.logger.info client
    rescue NotImplementedException
      Rails.logger.info 'WDS orchestration is not implemented yet'
    end
  end
end

class ::Host::Managed::Jail < Safemode::Jail
  allow :unattend_pass
end
