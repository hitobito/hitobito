#!/usr/bin/env rake
# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)


# custom requires
require 'ci/reporter/rake/rspec' unless Rails.env == 'production'

Jubla::Application.load_tasks
