set :output, 'log/cron.log'

every :week, at: '12:20am', roles: [:app] do
  rake 'hydrus:cleanup_tmp'
end
