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

  # A task to create a tag, push it, and deploy Hydrus.
  # Example usage if deploying to production.
  #
  #   rake hydrus:deploy DENV=production
  desc "Deploy Hydrus"
  task :deploy do
    # Get environment and version. The latter will serve as the tag.
    env =  ENV['DENV']
    vers = IO.read("#{Rails.root}/VERSION").strip
    abort "Specify a deployment environment: rake hydrus:deploy DENV=foo" unless env
    # Get user confirmation.
    print "Enter 'yes' to deploy to #{env} using tag #{vers}: "
    abort "Did not deploy." unless STDIN.gets.strip == 'yes'
    # Deploy.
    cmds = [
      "git tag -a #{vers} -m #{vers}",
      "git push origin --tags",
      "cd deploy",
      "sleep 1",
      "cap #{env} deploy",
      "cd -",
    ]
    system cmds.join(" && ")
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

