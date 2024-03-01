# encoding: utf-8

#  Copyright (c) 2012-2024, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

if Rake::Task.task_defined?('spec:features') # only if current environment knows rspec
  Rake::Task['spec:features'].actions.clear
  namespace :spec do
    RSpec::Core::RakeTask.new(:without_features) do |t|
      t.pattern = './spec/**/*_spec.rb'
      t.rspec_opts = '--tag ~type:feature'
    end

    RSpec::Core::RakeTask.new(:sphinx) do |t|
      t.pattern = './spec/**/*_spec.rb'
      t.rspec_opts = '--tag sphinx'
    end

    RSpec::Core::RakeTask.new(:features) do |t|
      t.pattern = './spec/features/**/*_spec.rb'
      t.rspec_opts = '--tag type:feature'
    end

    [:abilities, :decorators, :domain, :jobs, :regressions].each do |dir|
      RSpec::Core::RakeTask.new(dir) do |t|
        t.pattern = "./spec/#{dir}/**/*_spec.rb"
      end
    end

    namespace :features do
      # see https://www.puzzle.ch/de/blog/articles/2021/01/18/a-lenient-capybara
      desc 'Run feature specs at most three times to gracefully handle flaky specs'
      task :lenient do |t|
        sh 'rm -f tmp/examples.txt'
        puts "\nFIRST ATTEMPT\n"
        Rake::Task[t.name.gsub(/lenient/, 'start')].invoke
        next if $CHILD_STATUS.exitstatus.zero?

        puts "\nSECOND ATTEMPT\n"
        Rake::Task[t.name.gsub(/lenient/, 'retry')].invoke
        next if $CHILD_STATUS.exitstatus.zero?

        puts "\nLAST ATTEMPT\n"
        Rake::Task[t.name.gsub(/lenient/, 'last')].invoke
      end

      RSpec::Core::RakeTask.new('start') do |t|
        t.pattern = './spec/features/**/*_spec.rb'
        t.rspec_opts = '--tag type:feature'
        t.fail_on_error = false # don't stop the whole run
      end
      RSpec::Core::RakeTask.new('retry') do |t|
        t.rspec_opts = '--only-failures'
        t.fail_on_error = false # don't stop the whole run
      end
      RSpec::Core::RakeTask.new('last') do |t|
        t.rspec_opts = '--only-failures'
        t.fail_on_error = true # do fail the run
      end
    end
  end
end
