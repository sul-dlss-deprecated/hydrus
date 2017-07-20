node {
  env.RAILS_ENV = 'test'
  
  lock('hydrus') {
    stage ('Clean') {
      deleteDir()
    }

    stage('Build') {
      checkout scm

      withCredentials([zip(credentialsId: 'hydrus-config.zip', variable: 'CONFIG_DIR')]) {
        sh '''#!/bin/bash -l
        rvm use 2.3.4@hydrus
        echo $CONFIG_DIR
        ls $CONFIG_DIR
        cp $CONFIG_DIR/* config
        '''
      }

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
      lock('port-8983') {
        sh '''#!/bin/bash -l
        rvm use 2.3.4@hydrus
        bundle exec rake ci
        '''
      }
    }
  }
}
