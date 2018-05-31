module ForemanWds
  module UnattendedControllerExtensions
    def render_template(kind)
      return super unless kind == 'wds_localboot'

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
