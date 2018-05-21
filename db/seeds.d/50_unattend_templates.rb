kind = TemplateKind.unscoped.where(name: 'wds_unattend').first_or_create

ProvisioningTemplate.without_auditing do
  { 'unattend_2016.xml.erb' => 'Windows Server 2016' }.each do |tmpl_name, os_name|
    content = File.read(File.join(ForemanWds::Engine.root, 'app', 'views', 'foreman_wds', tmpl_name))
    tmpl = ProvisioningTemplate.unscoped.where(name: "Unattend #{os_name}").first_or_create(
      template_kind_id: kind.id,
      snippet: false,
      template: content
    )
    tmpl.attributes = {
      template: content,
      default:  true,
      vendor:   'Foreman WDS',
      locked:   false
    }
    tmpl.save!(validate: false) if tmpl.changes.present?
  end
end
