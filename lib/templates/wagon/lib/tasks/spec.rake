# encoding: utf-8

if Rake::Task.task_defined?('spec:features')
  # we DO have feature specs in this wagon.
  Rake::Task['spec:features'].actions.clear
  namespace :spec do
    RSpec::Core::RakeTask.new(:features) do |t|
      t.pattern = "./spec/features/**/*_spec.rb"
      t.rspec_opts = "--tag type:feature"
    end

    task all: ['spec:features', 'spec']
  end

else
  # we do NOT have feature specs in this wagon.
  namespace :spec do
    task all: 'spec'
  end
end
