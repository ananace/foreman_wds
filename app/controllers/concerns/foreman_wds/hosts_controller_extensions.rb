# frozen_string_literal: true

module ForemanWds
  module HostsControllerExtensions
    extend ActiveSupport::Concern

    included do
      before_action :cleanup_wds_params

      define_action_permission %w[wds_server_selected], :edit if respond_to? :define_action_permission
    end

    def wds_server_selected
      host = @host || item_object
      wds_facet = host.wds_facet || host.build_wds_facet
      wds_facet.wds_server_id ||= (params[:wds_facet] || params[:host])[:wds_server_id]

      render partial: 'wds_servers/image_select', locals: { item: wds_facet }
    end

    def cleanup_wds_params
      return unless params.dig(:host, :provision_method)

      # Don't create a WDS facet if not provisioning with it
      params[:host].delete :wds_facet_attributes if params.dig(:host, :provision_method) != 'wds'
    end
  end
end
