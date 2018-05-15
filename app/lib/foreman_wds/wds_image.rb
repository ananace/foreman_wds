class ForemanWds::WdsImage
  attr_accessor :id, :name, :description, :enabled, :file_name,
                :product_family, :product_name, :version
  attr_reader :wds_server

  def inspect
    Kernel.format('#<%<class>s:%<id>x %<variables>s>',
                  class: self.class,
                  id: (object_id << 1),
                  variables: instance_variables
                    .reject { |v| %i[@json @wds_server].include?(v) }
                    .map { |v| "#{v}=#{instance_variable_get(v).inspect}" }
                    .join(' '))
  end

  protected

  def json
    @json || {}
  end

  def initialize(json = {})
    @json = json if json.is_a? Hash
    @wds_server = self.json.delete(:wds_server)
    load!
  end

  def load!
    json.each do |k, v|
      sym = "#{k.to_s.underscore}=".to_sym
      send sym, v if respond_to? sym
    end
  end
end
