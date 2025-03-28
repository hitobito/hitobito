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

if defined?(STATS_DIRECTORIES)
  STATS_DIRECTORIES << ["Abilities", "#{Rails.root.join("app", "abilities")}"]
  STATS_DIRECTORIES << ["Decorators", "#{Rails.root.join("app", "decorators")}"]
  STATS_DIRECTORIES << ["Domain", "#{Rails.root.join("app", "domain")}"]
  STATS_DIRECTORIES << ["Jobs", "#{Rails.root.join("app", "jobs")}"]
  STATS_DIRECTORIES << ["Mailers", "#{Rails.root.join("app", "mailers")}"]
  STATS_DIRECTORIES << ["Serializers", "#{Rails.root.join("app", "serializers")}"]
  STATS_DIRECTORIES << ["Utils", "#{Rails.root.join("app", "utils")}"]
end
