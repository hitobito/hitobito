# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

if Rake::Task.task_defined?('spec:features') # only if current environment knows rspec
  Rake::Task['spec:features'].actions.clear
  namespace :spec do
    RSpec::Core::RakeTask.new(:features) do |t|
      # include phantomjs binary in path
      ENV['PATH'] += File::PATH_SEPARATOR + File.join(File.dirname(__FILE__), '..', '..', "script")
      t.pattern = "./spec/features/**/*_spec.rb"
      t.rspec_opts = "--tag type:feature"
    end

    RSpec::Core::RakeTask.new(:performance) do |t|
      t.pattern = "./spec/performance/**/*_spec.rb"
      t.rspec_opts = "--tag performance:true"
    end

    [:abilities, :decorators, :domain, :jobs, :regressions].each do |dir|
      RSpec::Core::RakeTask.new(dir) do |t|
        t.pattern = "./spec/#{dir}/**/*_spec.rb"
      end
    end
  end
end