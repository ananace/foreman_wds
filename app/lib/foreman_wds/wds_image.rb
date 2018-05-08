class ForemanWds::WdsImage
  attr_accessor :id, :name, :description, :enabled, :file_name,
                :product_family, :product_name, :version
  attr_reader :wds_server

  protected

  attr_reader :json

  def initialize(json = {})
    @json = {}
    @json = json if json.is_a? Hash
    @wds_server = @json.delete(:wds_server)
    load!
  end

  def load!
    json.each do |k, v|
      sym = "#{k.underscore}=".to_sym
      send sym, v if respond_to? sym
    end
  end
end
