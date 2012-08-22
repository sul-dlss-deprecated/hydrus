namespace :hydrus do
  desc "Hydrus Configurations"
  task :config do
    cp("#{Rails.root}/config/suri.yml.example", "#{Rails.root}/config/suri.yml") unless File.exists?("#{Rails.root}/config/suri.yml")
    cp("#{Rails.root}/config/database.yml.example", "#{Rails.root}/config/database.yml") unless File.exists?("#{Rails.root}/config/database.yml")
    cp("#{Rails.root}/config/solr.yml.example", "#{Rails.root}/config/solr.yml") unless File.exists?("#{Rails.root}/config/solr.yml")
    cp("#{Rails.root}/config/fedora.yml.example", "#{Rails.root}/config/fedora.yml") unless File.exists?("#{Rails.root}/config/fedora.yml")
    cp("#{Rails.root}/config/ur_apo_druid.yml.example", "#{Rails.root}/config/ur_apo_druid.yml") unless File.exists?("#{Rails.root}/config/ur_apo_druid.yml")
    cp("#{Rails.root}/config/workflow.yml.example", "#{Rails.root}/config/workflow.yml") unless File.exists?("#{Rails.root}/config/workflow.yml")
    cp("#{Rails.root}/config/ssl_certs.yml.example", "#{Rails.root}/config/ssl_certs.yml") unless File.exists?("#{Rails.root}/config/ssl_certs.yml")
  end

end
