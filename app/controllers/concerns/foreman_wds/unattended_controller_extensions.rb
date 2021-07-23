module ForemanWds
  module UnattendedControllerExtensions
    def host_template
      return wds_render_csr if params[:kind] == 'csr_attributes'
      return wds_deploy_localboot if params[:kind] == 'wds_localboot'
      super
    end

    private

    def wds_render_csr
      return unless verify_found_host
      return head(:method_not_allowed) unless allowed_to_install?

      template = ProvisioningTemplate.find_by_name('csr_attributes.yaml')
      return safe_render(template) if template

      return head(:not_found)
    end

    def wds_deploy_localboot
      return unless verify_found_host
      return head(:method_not_allowed) unless allowed_to_install?

      iface = @host.provision_interface

      # Deploy regular DHCP and local boot TFTP
      @host.provision_method = 'build'
      @host.build = false
      iface.send :rebuild_tftp
      iface.send :rebuild_dhcp

      @host.parameters.where(name: 'wds-specifictemplate').first_or_initialize.tap do |p|
        p.value = 'local-boot'
        p.save
      end

      render inline: "Success. Local boot template was deployed successfully.\n"
    rescue StandardError => e
      message = format('Failed to set local boot template: %{error}', error: e)
      logger.error message
      render text: message, status: :error, content_type: 'text/plain'
    end
  end
end
