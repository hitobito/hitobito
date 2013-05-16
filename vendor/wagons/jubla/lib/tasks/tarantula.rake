
desc "Crawl app with tarantula"
task :tarantula do
  sh 'rm -rf ../../../tmp/tarantula'
  sh 'bash -c "RAILS_ENV=test ../../../script/with_mysql rake db:test:prepare app:tarantula:test"'
end