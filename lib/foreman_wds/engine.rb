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

        # add menu entry
        menu :top_menu, :wds_servers,
             url_hash: { controller: :wds_servers, action: :index },
             caption: N_('WDS Servers'),
             parent: :infrastructure_menu

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
        HostsController.send(:include, ForemanWds::HostsControllerExtensions)
      rescue StandardError => e
        Rails.logger.fatal "foreman_wds: skipping engine hook (#{e})"
      end
    end
  end
end
