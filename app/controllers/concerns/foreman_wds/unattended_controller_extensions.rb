module ForemanWds
  module UnattendedControllerExtensions
    def host_template
      return wds_render_csr if params[:kind] == 'csr_attributes.yaml'
      return wds_deploy_localboot if params[:kind] == 'wds_localboot'
      super
    end

    def load_template_vars
      super unless params[:kind] == 'wds_localboot'
    end

    private

    def wds_render_csr
      return render(:plain => 'Host not in build mode') unless @host and @host.build?

      template = ProvisioningTemplate.find_by_name('csr_attributes.yaml')

      content = @host.render_template template: template
      raise Foreman::Exception.new(N_("Template '%s' didn't render correctly"), template.name) unless content

      render plain: content
    end

    def wds_deploy_localboot
      return render(:plain => 'Host not in build mode') unless @host and @host.build?

      iface = @host.provision_interface

      # Deploy regular DHCP and local boot TFTP
      @host.provision_method = 'build'
      @host.build = false
      iface.send :rebuild_tftp
      iface.send :rebuild_dhcp

      render inline: "Success. Local boot template was deployed successfully.\n"
    rescue StandardError => e
      message = format('Failed to set local boot template: %{error}', error: e)
      logger.error message
      render text: message, status: :error, content_type: 'text/plain'
    end
  end
end
