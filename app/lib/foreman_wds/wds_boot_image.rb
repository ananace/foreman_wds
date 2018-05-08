class WdsBootImage < WdsImage
  def initialize(json = {})
    super json
  end

  def reload
    @json = wds_server.boot_image(name)
    load!
  end
end
