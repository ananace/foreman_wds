class ForemanWds::WdsImage
  WDS_IMAGE_ARCHES = [nil, /^i.86|x86$/i, /^ia64$/i, /^x86_64|x64$/i, /^arm$/i].freeze
  WDS_ARCH_NAMES = [nil, 'x86', 'ia64', 'x64', 'arm'].freeze
  attr_accessor :id, :name, :description, :enabled, :file_name,
                :architecture, :product_family, :product_name, :version,
                :wds_server
  attr_reader :creation_time, :last_modification_time

  def inspect
    Kernel.format('#<%<class>s:%<id>x %<variables>s>',
                  class: self.class,
                  id: (object_id << 1),
                  variables: instance_variables
                    .reject { |v| %i[@json @wds_server].include?(v) }
                    .map { |v| "#{v}=#{instance_variable_get(v).inspect}" }
                    .join(' '))
  end

  def type_name
    self.class
        .name
        .demodulize
        .underscore
        .split('_')
        .map.with_index { |v, i| i.zero? ? v.upcase : v.capitalize }
        .join ' '
  end

  def architecture_name
    return architecture unless architecture.is_a?(Integer) && WDS_ARCH_NAMES[architecture]
    WDS_ARCH_NAMES[architecture]
  end

  def creation_time=(time)
    @creation_time = parse_time time
  end

  def last_modification_time=(time)
    @last_modification_time = parse_time time
  end

  def matches_architecture?(architecture)
    return nil unless WDS_IMAGE_ARCHES[self.architecture]
    architecture = architecture.name if architecture.is_a? Architecture
    !(WDS_IMAGE_ARCHES[self.architecture] =~ architecture).nil?
  end

  def marshal_dump
    @json
  end

  def marshal_load(json)
    @json = json
    load!
  end

  protected

  def initialize(json = {})
    @json = json if json.is_a? Hash
    @wds_server = self.json.delete(:wds_server)
    load!
  end

  def json
    @json || {}
  end

  def parse_time(time)
    return time unless time.is_a?(String) && time =~ /\/Date\(.*\)\//

    time = Time.at(time.scan(/\((.*)\)/).flatten.first.to_i / 1000)
    return time unless wds_server

    time.utc
    sec_diff = wds_server.timezone - Time.at(0).utc_offset
    time += sec_diff
    time.localtime
  end

  def load!
    json.each do |k, v|
      sym = "#{k.to_s.underscore}=".to_sym
      send sym, v if respond_to? sym
    end
  end
end
