node {
  env.RAILS_ENV = 'test'
  stage('Build') {
    checkout scm

    sh '''#!/bin/bash -l
    rvm use 2.3.4@hydrus --create

    gem install bundler
    bundle install
    bundle exec rake jetty:clean
    bundle exec rake hydra:jetty:config
    bundle exec rake hydrus:config
    bundle exec rake db:drop
    bundle exec rake db:migrate
    bundle exec rake db:test:prepare
    '''
  }

  stage('Test') {
    sh '''#!/bin/bash -l
    rvm use 2.3.4@hydrus
    bundle exec rake ci
    '''
  }
}
