module ForemanWds
  module UnattendedControllerExtensions
    def render_template(kind)
      return super unless kind == 'wds_localboot'

      iface = @host.provision_interface

      # Set PXE template parameters
      @kernel = @host.operatingsystem.kernel(@host.arch)
      @initrd = @host.operatingsystem.initrd(@host.arch)
      @mediapath = @host.operatingsystem.mediumpath(@host) if @host.operatingsystem.respond_to?(:mediumpath)

      # Xen requires additional boot files.
      @xen = @host.operatingsystem.xen(host.arch) if @host.operatingsystem.respond_to?(:xen)

      iface.send :default_pxe_render, @host.operatingsystem.pxe_loader_kind(@host)

      render inline: "Success. Local boot template was deployed successfully.\n"
    rescue StandardError => e
      message = format('Failed to set local boot template: %{error}', error: e)
      logger.error message
      render text: message, status: :error, content_type: 'text/plain'
    end
  end
end
