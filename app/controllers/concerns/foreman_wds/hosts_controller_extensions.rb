module ForemanWds
  module HostsControllerExtensions
    def wds_server_selected
      host = @host || item_object
      wds_facet = host.wds_facet || host.build_wds_facet
      wds_facet.wds_server_id ||= (params[:wds_facet] || params[:host])[:wds_server_id]

      render partial: 'wds_servers/image_select', locals: { item: wds_facet }
    end

    def host_params(top_level_hash = controller_name.singularize)
      # Don't create a WDS facet unless provisioning with it
      params[:host].delete :wds_facet_attributes if params[:host] && params[:host][:provision_method] != 'wds'

      super(top_level_hash)
    end

    def action_permission
      case params[:action]
      when 'wds_server_selected', 'wds_image_selected'
        :edit
      else
        super
      end
    end
  end
end
