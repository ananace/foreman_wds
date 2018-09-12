module ForemanWds
  class Engine < ::Rails::Engine
    engine_name 'foreman_wds'

    config.autoload_paths += Dir["#{config.root}/app/lib"]
    config.autoload_paths += Dir["#{config.root}/app/controllers/concerns"]
    config.autoload_paths += Dir["#{config.root}/app/models/concerns"]
    config.autoload_paths += Dir["#{config.root}/app/services"]

    initializer 'foreman_wds.load_app_instance_data' do |app|
      ForemanWds::Engine.paths['db/migrate'].existent.each do |path|
        app.config.paths['db/migrate'] << path
      end
    end

    initializer 'foreman_wds.register_plugin', before: :finisher_hook do |_app|
      Foreman::Plugin.register :foreman_wds do
        requires_foreman '>= 1.16'

        security_block :foreman_wds do
          permission :view_wds_servers, {
            wds_servers: %i[index show auto_complete_search wds_clients wds_images]
          }, resource_type: 'WdsServer'
          permission :create_wds_servers, {
            wds_servers: %i[create new]
          }, resource_type: 'WdsServer'
          permission :edit_wds_servers, {
            wds_servers: %i[edit update test_connection refresh_cache delete_wds_client]
          }, resource_type: 'WdsServer'
          permission :destroy_wds_servers, {
            wds_servers: %i[destroy]
          }, resource_type: 'WdsServer'

          # permission :edit_hosts, {
          #   hosts: %i[wds_server_selected wds_image_selected]
          # }, resource_type: 'Host'
        end

        Foreman::AccessControl.permissions(:edit_hosts).actions.concat [
          'hosts/wds_server_selected', 'hosts/wds_image_selected'
        ]

        role 'WDS Server Manager', %i[view_wds_servers create_wds_servers edit_wds_servers destroy_wds_servers]

        add_all_permissions_to_default_roles

        # add menu entry
        menu :top_menu, :wds_servers,
             url_hash: { controller: :wds_servers, action: :index },
             caption: N_('WDS Servers'),
             parent: :infrastructure_menu

        register_facet ForemanWds::WdsFacet, :wds_facet
        parameter_filter Host::Managed, wds_facet_attributes: %i[wds_server_id boot_image_name install_image_name]

        provision_method 'wds', N_('WDS Server')
        template_labels 'wds_unattend' => N_('WDS Unattend file template')
      end
    end

    assets_to_precompile =
      Dir.chdir(root) do
        Dir['app/assets/javascripts/**/*'].map do |f|
          f.split(File::SEPARATOR, 4).last
        end
      end

    initializer 'foreman_wds.assets.precompile' do |app|
      app.config.assets.precompile += assets_to_precompile
    end

    initializer 'foreman_wds.configure_assets', group: :assets do
      SETTINGS[:foreman_wds] = { assets: { precompile: assets_to_precompile } }
    end

    config.to_prepare do
      begin
        Host::Managed.send(:prepend, ForemanWds::HostExtensions)
        Nic::Managed.send(:prepend, ForemanWds::NicExtensions)
        HostsController.send(:prepend, ForemanWds::HostsControllerExtensions)
        UnattendedController.send(:prepend, ForemanWds::UnattendedControllerExtensions)

        ComputeResource.providers.each do |_k, const|
          Kernel.const_get(const).send(:prepend, ForemanWds::ComputeResourceExtensions)
        end
      rescue StandardError => e
        Rails.logger.fatal "foreman_wds: skipping engine hook (#{e})"
      end
    end

    rake_tasks do
      Rake::Task['db:seed'].enhance do
        ForemanWds::Engine.load_seed
      end
    end
  end
end
