module ForemanWds
  module NicExtensions
    def dhcp_update_required?
      return super if host.nil? || !host.wds? || host.wds_facet.nil?

      # DHCP entry for WDS depends on build mode
      return true if host.build_changed?
    end

    def boot_server
      return super if host.nil? || !host.wds? || host.wds_facet.nil?

      if host.build? # TODO: Support choosing local boot method
        return host.wds_server.next_server_ip unless subnet.dhcp.has_capability?(:DHCP, :dhcp_filename_hostname)
        return host.wds_server.next_server_name
      end

      super
    end

    def dhcp_records
      # Always recalculate dhcp records for WDS hosts, to allow different filename for the deleting and setting of a DHCP rebuild
      @dhcp_records = nil if !host.nil? && host.wds?
      super
    end

    def dhcp_attrs(record_mac)
      data = super(record_mac)
      return data if host.nil? || !host.wds?

      arch = WdsServer.wdsify_architecture(host.architecture)
      build_stage = host.build? ? :pxe : :local
      build_type = host.pxe_loader =~ /UEFI/i ? :uefi : :bios

      if build_stage == :pxe # TODO: Support choosing local boot method
        data[:filename] = WdsServer.bootfile_path(arch, build_type, build_stage)
      end

      # Don't compare filenames if trying to check for collisions, WDS entries differ on file depending on build mode
      data.delete :filename if caller_locations.map(&:label).include?('dhcp_conflict_detected?')

      data
    end
  end
end
