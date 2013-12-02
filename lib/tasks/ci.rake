# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

desc "Runs the tasks for a commit build"
task :ci => ['log:clear',
             'wagon:bundle:update',
             'db:migrate',
             'ci:setup:rspec',
             'spec:requests', # run request specs first to get coverage from spec
             'spec',
             'wagon:test',
             'rubocop']

namespace :ci do
  desc "Runs the tasks for a nightly build"
  task :nightly => ['log:clear',
                    'wagon:bundle:update',
                    'db:migrate',
                    'erd',
                    'ci:setup:rspec',
                    'spec:requests', # run request specs first to get coverage from spec
                    'spec',
                    'wagon:test',
                    'brakeman',
                    'rubocop:report',
                    #'qa' # stack level too deep on jenkins :(
                    ]
end
