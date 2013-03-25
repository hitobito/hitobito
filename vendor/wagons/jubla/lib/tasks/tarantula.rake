
desc "Crawl app with tarantula"
task :tarantula do
  sh 'bash -c "RAILS_ENV=test ../../../script/with_mysql rake db:test:prepare app:ts:restart app:tarantula:test"'
end