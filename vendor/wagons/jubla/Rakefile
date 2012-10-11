#!/usr/bin/env rake

begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

ENGINE_PATH = File.expand_path('..', __FILE__)
ENV['APP_ROOT'] ||= File.expand_path(__FILE__).split("vendor#{File::SEPARATOR}wagons").first

load 'wagons/wagon_tasks.rake'

load 'rspec/rails/tasks/rspec.rake'

require 'ci/reporter/rake/rspec' unless Rails.env == 'production'

namespace :zeus do
  task :remove do
    rm "zeus.json"
    rm "config/boot.rb"
    rm "config/application.rb"
    rm "config/environment.rb"
    rm "config/environments"
  end
  task :add do
    sh "ln -s ../../../zeus.json"
    sh "ln -s ../../../../config/boot.rb config/boot.rb"
    sh "ln -s ../../../../config/application.rb config/application.rb"
    sh "ln -s ../../../../config/environment.rb config/environment.rb"
    sh "ln -s ../../../../config/environments config/environments"
  end
end

