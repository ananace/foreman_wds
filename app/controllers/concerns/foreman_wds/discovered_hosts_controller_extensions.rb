# frozen_string_literal: true

module ForemanWds
  module DiscoveredHostsControllerExtensions
    def action_permission
      return :edit if params[:action] == 'wds_server_selected'

      super
    end
  end
end
