# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

ENV['RAILS_GROUPS'] = 'assets'

require 'spec_helper_base'
require 'capybara/poltergeist'

# define constant to reset in sphinx tests
DB_CLEANER_STRATEGY = :truncation

RSpec.configure do |config|
  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  config.before(:suite) do
    DatabaseCleaner.strategy = DB_CLEANER_STRATEGY
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end

Capybara.server_port = ENV['CAPYBARA_SERVER_PORT'].to_i if ENV['CAPYBARA_SERVER_PORT']


if ENV['HEADLESS'] == 'true'
  require 'headless'

  headless = Headless.new
  headless.start

  at_exit do
    headless.destroy
  end

  Capybara.default_wait_time = 5
elsif ENV['HEADLESS'] == 'false'
  # use selenium-webkit driver
else
  Capybara.register_driver :poltergeist do |app|
    options = { debug: false, inspector: true, timeout: 30 }
    driver = Capybara::Poltergeist::Driver.new(app, options)
  end
  Capybara.javascript_driver = :poltergeist
end
