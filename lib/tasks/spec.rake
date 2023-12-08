# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

if Rake::Task.task_defined?('spec:features') # only if current environment knows rspec
  Rake::Task['spec:features'].actions.clear
  namespace :spec do
    RSpec::Core::RakeTask.new(:sphinx) do |t|
      t.pattern = './spec/**/*_spec.rb'
      t.rspec_opts = '--tag sphinx'
    end

    RSpec::Core::RakeTask.new(:features) do |t|
      t.pattern = './spec/features/**/*_spec.rb'
      t.rspec_opts = '--tag type:feature'
    end

    RSpec::Core::RakeTask.new(:performance) do |t|
      t.pattern = './spec/performance/**/*_spec.rb'
      t.rspec_opts = '--tag performance:true'
    end

    [:abilities, :decorators, :domain, :jobs, :regressions].each do |dir|
      RSpec::Core::RakeTask.new(dir) do |t|
        t.pattern = "./spec/#{dir}/**/*_spec.rb"
      end
    end

    namespace :features do
      # see https://www.puzzle.ch/de/blog/articles/2021/01/18/a-lenient-capybara
      desc 'Run feature specs at most three times to gracefully handle flaky specs'
      task :lenient do
        sh 'rm -f tmp/example_status.txt'
        puts "\nFIRST ATTEMPT\n"
        Rake::Task['spec:features:start'].invoke
        next if $CHILD_STATUS.exitstatus.zero?
        puts "\nSECOND ATTEMPT\n"
        Rake::Task['spec:features:retry'].invoke
        next if $CHILD_STATUS.exitstatus.zero?
        puts "\nLAST ATTEMPT\n"
        Rake::Task['spec:features:last'].invoke
      end

      RSpec::Core::RakeTask.new('start') do |t|
        t.pattern = './spec/features/**/*_spec.rb'
        t.fail_on_error = false # don't stop the whole run
      end
      RSpec::Core::RakeTask.new('retry') do |t|
        t.fail_on_error = false # don't stop the whole run
        t.rspec_opts = '--only-failures'
      end
      RSpec::Core::RakeTask.new('last') do |t|
        t.fail_on_error = true # do fail the run
        t.rspec_opts = '--only-failures'
      end
    end
  end
end
