## Updating hydra-jetty submodule to a different version

This is old and known obsolete.  Candidate for removal.

```bash
git status   # Make sure your git status is clean.

# Make a backup of the hydrus dir. Include the trailing slash.
mkdir       ../backup_hydrus
rsync -a ./ ../backup_hydrus

# Restore jetty directory to its initial state.
cd jetty
git reset --hard HEAD
git clean -dfx
git status

# Checkout the commit you want to use.
git fetch
git checkout SHA1

# Back in the main hydrus projet, commit the submodule change.
cd ..
git status                           # Indicates jetty has changed.
git commit -am 'Updated hydra-jetty'

# Confirm that everything looks good.
git status
git submodule status

# Initialize the contents of jetty, etc.
rake hydrus:jetty_nuke
etc.

# If you do this work on the develop branch, you need to merge
# to master. Otherwise, you won't be able to set up the code on
# a new box, and tests won't run correctly on the master branch.

# Reset jetty directory on jenkinsqa.stanford.edu.
ssh jenkinsqa@jenkinsqa.stanford.edu
cd /jenkins/jobs/Hydrus-develop/workspace/jetty
git reset --hard HEAD
git clean -dfx
cd /jenkins/jobs/Hydrus/workspace/jetty
git reset --hard HEAD
git clean -dfx
```
