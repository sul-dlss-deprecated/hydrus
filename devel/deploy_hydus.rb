#! /usr/bin/env ruby

# A script used to deploy Hydrus.
#
# Could not get this to work as a Rake task -- specifically
# running the cap command under a different Ruby and gemset.
#
# Run the script without arguments for usage and instructions.

def deindent(s)
  return s.gsub(/\n  /, "\n").rstrip
end

# Usage information.
prereqs = "
  Prerequisites:
    - The commit to be deployed is currently active in your local Git repo.
    - You have pushed that commit.
    - The VERSION file contains the name of the tag to be deployed.
    - The tag has not been used already (unless --notag is used).
    - You have updated the CHANGELOG.
    - Your Kerberos authentication is fresh.
".strip

usage = deindent("
  Usage:

    ruby #{$PROGRAM_NAME} DEPLOY_ENV [--notag] [--debug]

    DEPLOY_ENV   Environment to deploy to: dortest, production, etc.
    --notag      If given, Git tag is not created.
    --debug      If given, commands are printed, not run.

  What the task does:
    - Creates a Git tag and pushes it (unless --notag is used).
    - Deploys the commit linked to that tag to the environment specified.

  #{prereqs}
")

# Get environment and version. The latter will serve as the tag.
debug = !! ARGV.delete('--debug')
notag = !! ARGV.delete('--notag')
env   = ARGV.shift
tag   = IO.read('VERSION').strip
abort(usage) unless env

# Get user confirmation.
puts deindent("
  #{prereqs}

  Deployment:
    To:          #{env}
    Tag:         #{tag}
    No-tag mode: #{notag}
    Debug mode:  #{debug}
")
print "\nEnter 'yes' to confirm: "
abort("\nDid not deploy.") unless STDIN.gets.strip == 'yes'
puts

# Run commands.
cmds = [
  "git tag -a #{tag} -m #{tag}",
  "git push origin --tags",
  "bash -i -c 'cd deploy && . .rvmrc && cap #{env} deploy'",
]

cmds.each do |c|
  c = "echo #{c}" if debug
  next if notag && c =~ /git/
  system(c) or abort("\nCommand failed: #{c.inspect}")
end
