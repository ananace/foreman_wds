module ForemanWds
  module HostExtensions
    attr_accessor :wds_server_id, :wds_image_name

    def capabilities
      return super + [:wds] if os.nil? || os.family == 'Windows'
      super
    end

    def wds_build?
      provision_method == 'wds'
    end

    def wds?
      managed? && wds_build? && SETTINGS[:unattended]
    end

    def wds_server
      @wds_server ||= WdsServer.find(wds_server_id)
    end
  end
end
