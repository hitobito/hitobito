# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

desc "Runs the tasks for a commit build"
task :ci => ['log:clear',
             'rubocop',
             'db:migrate',
             'ci:setup:rspec',
             'spec:features', # run feature specs first to get coverage from spec
             'spec']

namespace :ci do
  desc "Runs the tasks for a nightly build"
  task :nightly => ['log:clear',
                    'db:migrate',
                    'erd',
                    'ci:setup:rspec',
                    'spec:features', # run feature specs first to get coverage from spec
                    'spec',
                    'rubocop:report',
                    'brakeman',
                    ]

  desc "Run the tasks for a wagon commit build"
  task :wagon do
    Rake::Task['log:clear'].invoke
    wagon_exec('bundle exec rake app:rubocop app:ci:setup:rspec spec')
  end

  namespace :wagon do

    desc "Run the tasks for a wagon nightly build"
    task :nightly do
      Rake::Task['log:clear'].invoke
      wagon_exec('bundle exec rake app:ci:setup:rspec spec app:rubocop:report app:brakeman')
      Rake::Task['erd'].invoke
    end

  end

  def wagon_exec(cmd)
    cmd += ' -t' if Rake.application.options.trace
    ENV['CMD'] = cmd
    Rake::Task['wagon:exec'].invoke
  end
end
