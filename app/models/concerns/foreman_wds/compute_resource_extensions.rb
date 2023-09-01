# frozen_string_literal: true

module ForemanWds
  module ComputeResourceExtensions
    def capabilities
      super + [:wds]
    end
  end
end
