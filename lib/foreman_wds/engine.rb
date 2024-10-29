# frozen_string_literal: true

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

    initializer 'foreman_wds.register_plugin', before: :finisher_hook do |app|
      app.reloader.to_prepare do
        require_relative 'register'
      end
    end

    config.to_prepare do
      Host::Managed.prepend ForemanWds::HostExtensions
      Nic::Managed.prepend ForemanWds::NicExtensions
      HostsController.include ForemanWds::HostsControllerExtensions
      UnattendedController.prepend ForemanWds::UnattendedControllerExtensions

      ComputeResource.providers.each_value do |const|
        Kernel.const_get(const).send(:prepend, ForemanWds::ComputeResourceExtensions)
      end

      if Foreman::Plugin.installed?('foreman_discovery')
        DiscoveredHostsController.include ForemanWds::HostsControllerExtensions
        DiscoveredHostsController.prepend ForemanWds::DiscoveredHostsControllerExtensions
      end
    rescue StandardError => e
      Rails.logger.fatal "foreman_wds: skipping engine hook (#{e})"
    end

    rake_tasks do
      Rake::Task['db:seed'].enhance do
        ForemanWds::Engine.load_seed
      end
    end
  end
end
