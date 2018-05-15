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
  end
end
