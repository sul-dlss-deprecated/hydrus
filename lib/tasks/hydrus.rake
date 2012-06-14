namespace :hydrus do
  desc "Hydrus Configurations"
  task :config do
    cp("#{Rails.root}/config/suri.yml.example", "#{Rails.root}/config/suri.yml") unless File.exists?("#{Rails.root}/config/suri.yml")
  end

end