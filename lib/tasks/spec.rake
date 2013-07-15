
if Rake::Task.task_defined?('spec:requests') # only if current environment knows rspec
  Rake::Task['spec:requests'].actions.clear
  namespace :spec do
    RSpec::Core::RakeTask.new(:requests => 'db:test:prepare') do |t|
      # include phantomjs binary in path
      ENV['PATH'] += File::PATH_SEPARATOR + File.join(File.dirname(__FILE__), '..', '..', "script")
      t.pattern = "./spec/requests/**/*_spec.rb"
      t.spec_opts = "--tag type:request"
    end

    RSpec::Core::RakeTask.new(:performance => 'db:test:prepare') do |t|
      t.pattern = "./spec/performance/**/*_spec.rb"
      t.spec_opts = "--tag performance:true"
    end

    [:abilities, :decorators, :domain, :jobs, :regressions].each do |dir|
      RSpec::Core::RakeTask.new(dir => 'db:test:prepare') do |t|
        t.pattern = "./spec/#{dir}/**/*_spec.rb"
      end
    end
  end
end