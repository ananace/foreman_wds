# frozen_string_literal: true

class WdsServersController < ApplicationController
  include Foreman::Controller::AutoCompleteSearch
  include Foreman::Controller::Parameters::WdsServer

  before_action :find_server, except: %i[index new create]

  def model_of_controller
    WdsServer
  end

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

  def test_connection
    # wds_id is posted from AJAX function. wds_id is nil if new
    if params[:wds_id].present?
      @wds_server = WdsServer.authorized(:edit_wds_server).find(params[:wds_id])
      @wds_server.attributes = wds_server_params.reject { |k, v| k == :password && v.blank? }
    else
      @wds_server = WdsServer.new(wds_server_params)
    end

    @wds_server.test_connection
    render partial: 'form', locals: { wds_server: @wds_server }
  end

  def refresh_cache
    @wds_server.refresh_cache

    render partial: 'form', locals: { wds_server: @wds_server }
  end

  def wds_clients
    @clients = @wds_server.clients

    render partial: 'wds_servers/clients/list'
  end

  def wds_images
    @images = @wds_server.boot_images + @wds_server.install_images

    render partial: 'wds_servers/images/list'
  end

  def delete_wds_client
    host = Host::Managed.find(params[:client])
    # raise unless host
    client = @wds_server.client(host)
    # raise unless client

    @wds_server.delete_client(host)
  end

  private

  def find_server
    @wds_server = WdsServer.find(params[:id])
  end

  def action_permission
    case params[:action]
    when 'wds_clients', 'wds_images'
      :view
    when 'test_connection', 'refresh_cache', 'delete_wds_client'
      :edit
    else
      super
    end
  end
end
