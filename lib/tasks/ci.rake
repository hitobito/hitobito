# encoding: utf-8
# frozen_string_literal: true

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# rubocop:disable Rails/RakeEnvironment

desc 'Runs the tasks for a commit build'
task :ci do
  tasks_to_skip = ENV['skip_tasks'].present? ? ENV['skip_tasks'].split(',') : []
  tasks = ['log:clear',
           'rubocop',
           'db:migrate',
           'ci:setup:env',
           'ci:setup:rspec',
           'spec:sphinx',
           'spec:features', # run feature specs first to get coverage from spec
           'spec'].delete_if { |task| tasks_to_skip.include?(task) }

  tasks.each { |task| Rake::Task[task].invoke }
end

namespace :ci do
  desc 'Runs the tasks for a nightly build'
  task nightly: ['log:clear',
                 'db:migrate',
                 'erd',
                 'doc:all',
                 'ci:setup:env',
                 'ci:setup:rspec',
                 # 'spec:features', # run feature specs first to get coverage from spec
                 'spec',
                 'rubocop:report',
                 'brakeman']

  desc 'Run the tasks for a wagon commit build'
  task :wagon do

    Rake::Task['log:clear'].invoke

    wagon_exec('DISABLE_DATABASE_ENVIRONMENT_CHECK=1 ' \
               'bundle exec rake app:rubocop app:ci:setup:rspec spec:all')
  end

  namespace :setup do
    task :env do
      ENV['CI'] = 'true'
    end
  end

  namespace :wagon do

    desc 'Run the tasks for a wagon nightly build'
    task :nightly do
      Rake::Task['log:clear'].invoke
      wagon_exec('DISABLE_DATABASE_ENVIRONMENT_CHECK=1 ' \
                 'bundle exec rake app:ci:setup:env ' \
                 'app:ci:setup:rspec spec:all app:rubocop:report app:brakeman')
      Rake::Task['erd'].invoke
    end

  end

  def wagon_exec(cmd)
    cmd += ' -t' if Rake.application.options.trace
    ENV['CMD'] = cmd
    Rake::Task['wagon:exec'].invoke
  end
end

# rubocop:enable Rails/RakeEnvironment
