#! /bin/bash

PROJ_DIR='/home/lyberadmin/hydrus/current'
RENV='RAILS_ENV=dortest'
VM='lyberadmin@hydrus-test.stanford.edu'

ssh $VM "cd $PROJ_DIR && $RENV bundle exec $@"
