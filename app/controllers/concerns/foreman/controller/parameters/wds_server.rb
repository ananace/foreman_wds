# frozen_string_literal: true

module Foreman::Controller::Parameters::WdsServer
  extend ActiveSupport::Concern

  class_methods do
    def wds_server_params_filter
      Foreman::ParameterFilter.new(::WdsServer).tap do |filter|
        filter.permit :name,
                      :description,
                      :url,
                      :user,
                      :password
      end
    end
  end

  def wds_server_params
    self.class.wds_server_params_filter.filter_params(params, parameter_filter_context, :wds_server)
  end
end
