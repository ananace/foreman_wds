class WdsServersController < ::ApplicationController
  include Foreman::Controller::AutoCompleteSearch
  include Foreman::Controller::Parameters::WdsServer

  before_action :find_server, only: %i[show edit update destroy]

  def index
    @wds_servers = resource_base_search_and_page
  end

  def show; end

  def new
    @wds_server = WdsServer.new
  end

  def edit; end

  def create
    @wds_server = WdsServer.new(wds_server_params)
    if @wds_server.save
      process_success success_redirect: wds_server_path(@wds_server)
    else
      process_error
    end
  end

  def update
    if @wds_server.update(wds_server_params)
      process_success
    else
      process_error
    end
  end

  def destroy
    if @wds_server.destroy
      process_success
    else
      process_error
    end
  end

  private

  def find_server
    @wds_server = WdsServer.find(params[:id])
  end
end
