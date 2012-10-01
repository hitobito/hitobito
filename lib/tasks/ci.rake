desc "Runs the tasks for a commit build"
task :ci => ['log:clear',
             'db:migrate',
             'ci:setup:rspec',
             'spec',
             'wagon:test']

namespace :ci do
  desc "Runs the tasks for a nightly build"
  task :nightly => ['log:clear', 
                    'db:migrate', 
                    #'erd',
                    #'brakeman',
                    'ci:setup:rspec',
                    'spec',
                    'wagon:test',
                    #'spec:integration'
                    ]
end

desc "Add column annotations to active records"
task :annotate do
  sh 'annotate -p before'
end

desc "Run brakeman"
task :brakeman do
  sh 'brakeman -o brakeman-output.tabs'
end

desc "Run quality analysis"
task :qa do
  sh 'rails_best_practices -x config,db .'
end

namespace :erd do
  task :options => :customize
  task :customize do
    ENV['attributes']  ||= 'content,inheritance,foreign_keys,timestamps'
    ENV['indirect']    ||= 'false'
    ENV['orientation'] ||= 'vertical'
    ENV['notation']    ||= 'uml'
    ENV['filename']    ||= 'doc/models'
    ENV['filetype']    ||= 'png'
  end
end
