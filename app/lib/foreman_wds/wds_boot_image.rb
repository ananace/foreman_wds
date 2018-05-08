class ForemanWds::WdsBootImage < ForemanWds::WdsImage
  def initialize(json = {})
    super json
  end

  def reload
    return false if wds_server.nil?
    @json = wds_server.boot_image(name)
    load!
  end
end
