class WdsInstallImage < WdsImage
  attr_accessor :compression, :dependent_files, :format, :image_group,
                :partition_style, :security, :staged, :unattend_file_present

  def initialize(json = {})
    super json
  end

  def reload
    @json = wds_server.install_image(name)
    load!
  end
end
