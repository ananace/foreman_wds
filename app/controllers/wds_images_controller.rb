class WdsImagesController < ApplicationController
  before_action :find_wds_server
  before_action :find_resource, only: %i[edit update destroy]

  def index
    @images = @wds_server.send params[:image_type].to_sym == :boot ? :boot_images : :install_images

    respond_to do |format|
      format.html { render partial: 'images/list' }
      format.json do
        render json: @images.select do |img|
          keep = true
          keep &&= img[:architecture] == wdsify_arch
          keep &&= img[:product_family] == wdsify_os.family
          keep
        end
      end
    end
  end

  def new
    @image = {}
  end

  def create
    # TODO
    process_error
  end

  def edit; end

  def update
    # TODO
    process_error
  end

  def destroy
    # TODO
    process_error
  end

  private

  def wdsify_arch(arch = params[:architecture_id])
    arch = Architecture.find arch unless arch.is_a? Architecture
    case arch.name.to_sym
    when :i386, :i686, :i986, :x86
      0
    when :x86_64, :x64
      9
    end
  end

  def wdsify_os(os = params[:operatingsystem_id])
    os = Operatingsystem.find os unless os.is_a? Operatingsystem
    os.type
  end

  def find_wds_server
    # .authorized(:view_wds_servers).find
    @wds_server = WdsServer.find(params[:wds_server_id])
  end

  def find_resource
    images = @wds_server.send params[:image_type].to_sym == :boot ? :boot_images : :install_images
    @image = images.find { |img| img[:image_name] == params[:image_name] }
  end
end
