# frozen_string_literal: true

# Runs remediation even if the object doesn't need it according to its object_version.
force = !! ARGV.delete('--force')

# Does not save the Fedora object after remediation code is run.
no_save = !! ARGV.delete('--no-save')

# Does not try to open a new version and close it.
no_versioning = !! ARGV.delete('--no-versioning')

# Invoke the runner.
Hydrus::RemediationRunner.new(
  force: force,
  no_save: no_save,
  no_versioning: no_versioning).run
