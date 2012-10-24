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
                    'erd',
                    'ci:setup:rspec',
                    'spec',
                    'wagon:test',
                    'spec:requests',
                    'brakeman',
                    #'qa' raises StackLevelTooDeep for Ruby 1.9.3.p0
                    ]
end

desc "Add column annotations to active records"
task :annotate do
  sh 'annotate -p before'
end

desc "Run brakeman"
task :brakeman do
  # some files seem to cause brakeman to hang. ignore them
  ignores = %w(app/views/people_filters/_form.html.haml)
  begin
    Timeout.timeout(120) do
      sh "brakeman -o brakeman-output.tabs --skip-files #{ignores.join(',')}"
    end
  rescue Timeout::Error => e
    puts "\nBrakeman took too long. Aborting."
  end
end

desc "Run quality analysis"
task :qa do
  # do not fail if we find issues
  sh 'rails_best_practices -x config,db -f html --vendor .' rescue nil
  true
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

namespace :spec do
  task :requests => :enable_requests
  task :enable_requests do
    ENV['PATH'] += File::PATH_SEPARATOR + File.join(File.dirname(__FILE__), '..', '..', "script")
    ENV['SPEC_OPTS'] ||= ""
    ENV['SPEC_OPTS'] += " --tag type:request"
  end
end

desc "Load the mysql database configuration for the following tasks"
task :mysql do
  ENV['RAILS_DB_ADAPTER'] = 'mysql2'
  ENV['RAILS_DB_NAME']    = 'jubla_test'
  ENV['RAILS_DB_SOCKET']  = '/var/lib/mysql/mysql.sock'
end
