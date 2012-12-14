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

  desc "Deploy Hydrus"
  task :deploy do
    prereqs = "Prerequisites:
        - The commit to be deployed is currently active in your local Git repo.
        - You have pushed that commit.
        - The VERSION file contains the name of the tag.
        - The tag has not been used already.
        - You have updated the CHANGELOG.
        - Your Kerberos authentication is fresh.
    ".rstrip
    usage = "
      Usage:

        rake hydrus:deploy DENV=xxx

        Where xxx is the environment to deploy to: dortest, production, etc.

      What this task does:
        - Creates a Git tag and pushes it.
        - Deploys the commit linked to that tag to the environment specified.

      #{prereqs}
    ".gsub(/\n {6}/, "\n").rstrip
    # Get environment and version. The latter will serve as the tag.
    env =  ENV['DENV']
    vers = IO.read("#{Rails.root}/VERSION").strip
    abort(usage) unless env
    # Get user confirmation.
    confirm = "
      #{prereqs}

      Deployment:
        To:  #{env}
        Tag: #{vers}
    ".gsub(/\n {6}/, "\n").rstrip
    puts confirm
    print "\nEnter 'yes' to confirm: "
    abort("\nDid not deploy.") unless STDIN.gets.strip == 'yes'
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

