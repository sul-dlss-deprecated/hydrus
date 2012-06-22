namespace :hydrus do
  desc "Hydrus Configurations"
  task :config do
    cp("#{Rails.root}/config/suri.yml.example", "#{Rails.root}/config/suri.yml") unless File.exists?("#{Rails.root}/config/suri.yml")
    cp("#{Rails.root}/config/database.yml.example", "#{Rails.root}/config/database.yml") unless File.exists?("#{Rails.root}/config/database.yml")
    cp("#{Rails.root}/config/solr.yml.example", "#{Rails.root}/config/solr.yml") unless File.exists?("#{Rails.root}/config/solr.yml")
    cp("#{Rails.root}/config/fedora.yml.example", "#{Rails.root}/config/fedora.yml") unless File.exists?("#{Rails.root}/config/fedora.yml")
  end

end
