# A script used to deploy Hydrus.
#
# Could not get this to work as a Rake task -- specifically
# running the final cap command in a different directory under
# a different Ruby and gemset.
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
    - The VERSION file contains the name of the tag.
    - The tag has not been used already.
    - You have updated the CHANGELOG.
    - Your Kerberos authentication is fresh.
    - Use are using RVM gemsets.
".strip

usage = deindent("
  Usage:

    ruby #{$PROGRAM_NAME} DEPLOY_ENV [--debug]

    DEPLOY_ENV   Environment to deploy to: dortest, production, etc.
    --debug      If given, commands are printed, not run.

  What the task does:
    - Creates a Git tag and pushes it.
    - Deploys the commit linked to that tag to the environment specified.

  #{prereqs}
")

# Get environment and version. The latter will serve as the tag.
debug = ARGV.delete('--debug')
env   = ARGV.shift
vers  = IO.read('VERSION').strip
abort(usage) unless env

# Get user confirmation.
puts deindent("
  #{prereqs}

  Deployment:
    To:  #{env}
    Tag: #{vers}
")
print "\nEnter 'yes' to confirm: "
abort("\nDid not deploy.") unless STDIN.gets.strip == 'yes'
puts

# Run commands.
cmds = [
  "git tag -a #{vers} -m #{vers}",
  "git push origin --tags",
  "bash -i -c 'cd deploy && cap cap #{env} deploy'",
]

cmds.each do |c|
  c = "echo #{c}" if debug
  system(c) or abort("\nCommand failed: #{c.inspect}")
end
