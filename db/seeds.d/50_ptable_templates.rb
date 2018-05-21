Ptable.without_auditing do
  { 'windows_ptable.xml.erb' => 'Windows default' }.each do |tmpl_file, tmpl_name|
    content = File.read(File.join(ForemanWds::Engine.root, 'app', 'views', 'foreman_wds', tmpl_file))
    tmpl = Ptable.unscoped.where(name: tmpl_name).first_or_create(
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
