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
| >= 3.12         | >= 0.0.4       |
| >= 1.23         | any            |

## Installation

See the [Plugins install instructions, advanced installation from gems](https://theforeman.org/plugins/#2.3AdvancedInstallationfromGems) for information on how to install this plugins.

This plugin has JavaScript assets that require precompilation if installed into a packaged Foreman install.  
You will need to install the `foreman-assets` package and run `foreman-rake plugin:assets:precompile[foreman_wds]` after installing it from gem.

## Contributing

Bug reports and pull requests are welcome on the LiU GitLab at https://gitlab.liu.se/ITI/foreman_wds or on GitHub at https://github.com/ananace/foreman_wds

## License

The gem is available as open source under the terms of the [GPL-3.0 License](https://opensource.org/licenses/GPL-3.0).
