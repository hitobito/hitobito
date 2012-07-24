desc "Runs the tasks for a commit build"
task :ci => ['log:clear',
             'db:migrate',
             'ci:setup:rspec',
             'spec']

namespace :ci do
  desc "Runs the tasks for a nightly build"
  task :nightly => ['log:clear', 
                    'db:migrate', 
                    'diagram:models:complete:png', 
                    'diagram:controllers:complete:png', 
                    'ci:setup:rspec',
                    'spec:rcov',
                    'spec:integration']
end

desc "Add column annotations to active records"
task :annotate do
  sh 'annotate -p before'
end

desc "Add column annotations to active records"
task :qa do
  sh 'rails_best_practices -x config,db .'
end