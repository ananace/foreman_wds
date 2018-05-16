module ForemanWds
  module HostsControllerExtensions
    def wds_server_selected
      item = @host || item_object
      item.wds_server_id = params[:host][:wds_server_id]

      render partial: 'wds_servers/image_select', locals: { item: item }
    end
  end
end
