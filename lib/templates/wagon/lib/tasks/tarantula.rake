# frozen_string_literal: true

desc 'Crawl app with tarantula'
task :tarantula do # rubocop:disable Rails/RakeEnvironment
  sh 'rm -rf ../../../tmp/tarantula'
  sh 'rm -rf ../hitobito/tmp/tarantula'
  sh "bash -c \"RAILS_ENV=test #{ENV['APP_ROOT']}/bin/with_mysql " \
     'rake app:tarantula:test"'
end
