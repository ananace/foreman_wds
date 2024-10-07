# frozen_string_literal: true

Foreman::Plugin.register :foreman_wds do
  requires_foreman '>= 3.12'

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
  end

  Foreman::AccessControl.permission(:edit_hosts).actions.push(
    'hosts/wds_server_selected', 'hosts/wds_image_selected'
  )

  role 'WDS Server Manager',
       %i[view_wds_servers create_wds_servers edit_wds_servers destroy_wds_servers],
       'Role granting permissions full management permissions for WDS servers.'

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
