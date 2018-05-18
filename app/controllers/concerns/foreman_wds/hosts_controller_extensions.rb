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
      keep_param(params, top_level_hash, :compute_attributes, :wds_facet_attributes) do
        self.class.host_params_filter.filter_params(params, parameter_filter_context, top_level_hash)
      end
    end
  end
end
