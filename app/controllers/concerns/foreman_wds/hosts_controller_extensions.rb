module ForemanWds
  module HostsControllerExtensions
    def wds_server_selected
      host = @host || item_object
      wds_facet = host.wds_facet || host.build_wds_facet
      wds_facet.wds_server_id ||= (params[:wds_facet] || params[:host])[:wds_server_id]

      render partial: 'wds_servers/image_select', locals: { item: wds_facet }
    end

    # FIXME Ugly hack
    # Forcefully adds wds_facet to the permitted params
    def host_params(top_level_hash = controller_name.singularize)
      params[:host][:wds_facet].permit! if params.key?(:host) && params[:host][:wds_facet].is_a?(ActionController::Parameters)

      super(top_level_hash)
    end
  end
end
