module ForemanWds
  module HostsControllerExtensions
    def wds_server_selected
      host = @host || item_object
      wds_facet = host.wds_facet || host.build_wds_facet
      wds_facet.wds_server_id ||= (params[:wds_facet] || params[:host])[:wds_server_id]

      render partial: 'wds_servers/image_select', locals: { item: wds_facet }
    end

    def host_template
      return super unless params[:kind] == 'wds_localboot'

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

    def host_params(top_level_hash = controller_name.singularize)
      # Don't create a WDS facet unless provisioning with it
      params[:host].delete :wds_facet_attributes if params[:host] && params[:host][:provision_method] != 'wds'

      super(top_level_hash)
    end
  end
end
