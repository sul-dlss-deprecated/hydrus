namespace :hydrus do
  desc "Hydrus Configurations"
  task :config do
    files = %w(
      database.yml
      fedora.yml
      solr.yml
      ssl_certs.yml
      suri.yml
      ur_apo_druid.yml
      workflow.yml
    )
    files.each do |f|
      f = "#{Rails.root}/config/#{f}"
      cp("#{f}.example", f) unless File.exists?(f)
    end
  end
end

desc "rails server with suppressed output"
task :server => :environment do
  system "rake jetty:start" unless `rake jetty:status` =~ /^Running:/
  cmd = [
    "rails s 2>&1",
    "grep --line-buffered -Fv 'WARN  Could not determine content-length of response'",
    "grep --line-buffered -v  '^Loaded datastream druid:'",
    "grep --line-buffered -v  '^Loaded datastream list'",
    "grep --line-buffered -v  '^Solr response: '"
  ].join(' | ')
  system cmd
end

