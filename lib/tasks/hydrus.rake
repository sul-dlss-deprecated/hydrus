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
  # Note: to get this to work nicely, we also set the app to generate
  # unbuffered output: see config/application.rb.
  system "rake jetty:start" unless `rake jetty:status` =~ /^Running:/
  exclusions = [
    "WARN  Could not determine content-length of response",
    "^Loaded datastream druid:",
    "^Loaded datastream list",
    "^Solr response: "
  ]
  regex = exclusions.join("|")
  cmd = [
    "rails server 2>&1",
    %Q<ruby -ne 'BEGIN { STDOUT.sync = true }; print $_ unless $_ =~ /#{regex}/'>
  ].join(' | ')
  system(cmd)
end

