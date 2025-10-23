#!/usr/bin/env rake

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path("../config/application", __FILE__)

# custom requires
require "ci/reporter/rake/rspec" unless Rails.env.production?
if Rails.env.development?
  require "rails-erd"
end

Hitobito::Application.load_tasks

Rake::Task.tasks.each do |task|
  task.enhance do
    PaperTrail.request.whodunnit = "rake #{task.name}"
    PaperTrail.request.controller_info = {mutation_id: SecureRandom.uuid}
  end
end

if defined?(Rails::CodeStatistics)
  Rails::CodeStatistics.register_directory("Abilities", "#{Rails.root.join("app", "abilities")}")
  Rails::CodeStatistics.register_directory("Decorators", "#{Rails.root.join("app", "decorators")}")
  Rails::CodeStatistics.register_directory("Domain", "#{Rails.root.join("app", "domain")}")
  Rails::CodeStatistics.register_directory("Jobs", "#{Rails.root.join("app", "jobs")}")
  Rails::CodeStatistics.register_directory("Mailers", "#{Rails.root.join("app", "mailers")}")
  Rails::CodeStatistics.register_directory("Serializers", "#{Rails.root.join("app", "serializers")}")
  Rails::CodeStatistics.register_directory("Utils", "#{Rails.root.join("app", "utils")}")
end
