# Foreman Windows Deployment Service

This plugin adds extended support to Foreman for querying and orchestrating WDS servers.

*Nota Bene*; to support locally booting your installation, you need to have a regular DHCP/TFTP setup in place, that can serve PXE files for the PXE loader chosen for the WDS host.  
If you don't want the lifecycle management features of Foreman, you can ignore this requirement and only PXE boot the WDS host when it is to be built.

### Not yet implemented:

- Install image orchestration
- Unattend file deployment
  - Recommended to build a http client (curl/wget/etc) into your boot image and download `https://foreman.example.com/unattend/wds_unattend` to drive the setup.

## Compatibility

| Foreman Version | Plugin Version |
| --------------- | -------------- |
| >= 1.16         | any            |

## Installation

See [Plugins install instructions](https://theforeman.org/plugins/) for information on how to install Foreman plugins.

## Usage

TODO

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ananace/foreman_wds

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
