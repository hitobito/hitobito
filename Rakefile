# encoding: utf-8
#!/usr/bin/env rake

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)


# custom requires
require 'ci/reporter/rake/rspec' unless Rails.env.production?
if Rails.env.development?
  require 'rails-erd'
  require 'rails_code_qa'
end

Hitobito::Application.load_tasks


STATS_DIRECTORIES << ['Abilities', "#{Rails.root}/app/abilities"]
STATS_DIRECTORIES << ['Decorators', "#{Rails.root}/app/decorators"]
STATS_DIRECTORIES << ['Domain', "#{Rails.root}/app/domain"]
STATS_DIRECTORIES << ['Jobs', "#{Rails.root}/app/jobs"]
STATS_DIRECTORIES << ['Mailers', "#{Rails.root}/app/mailers"]
STATS_DIRECTORIES << ['Utils', "#{Rails.root}/app/utils"]
