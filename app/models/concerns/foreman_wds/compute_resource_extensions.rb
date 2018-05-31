module ForemanWds
  module ComputeResourceExtensions
    def capabilities
      super + [:wds]
    end
  end
end
