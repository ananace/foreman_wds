module ForemanWds
  module NicExtensions
    def dhcp_attrs(record_mac)
      data = super(record_mac)
      return data unless host || host.wds?

      wds_server = host.wds_server
      arch = WdsServer.wdsify_architecture(host.architecture)

      data[:nextServer] = wds_server.next_server_ip
      data[:filename] = WdsServer.bootfile_path(arch, host.build? ? :pxe : :local, host.pxe_loader =~ /UEFI/i ? :uefi : :bios)

      data
    end
  end
end
