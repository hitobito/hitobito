# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

def init
  init_simplecov
  init_environment
  init_rspec
  init_capybara
end

def init_simplecov
  require 'simplecov'
  require 'simplecov-rcov'
  SimpleCov.start 'rails'
  SimpleCov.coverage_dir 'spec/coverage'
  # use this formatter for jenkins compatibility
  SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter
end

def init_environment
  ENV['RAILS_ENV'] ||= 'test'
  ENV['RAILS_GROUPS'] = 'assets'
  require File.expand_path('../../config/environment', __FILE__)
  require 'rspec/rails'
  require 'rspec/autorun'
  require 'cancan/matchers'
  require 'capybara/poltergeist'

  # Requires supporting ruby files with custom matchers and macros, etc,
  # in spec/support/ and its subdirectories.
  Dir[Rails.root.join('spec/support/**/*.rb')].sort.each { |f| require f }

  # Add test locales
  Rails.application.config.i18n.load_path += Dir[Rails.root.join('spec', 'support', 'locales', '**', '*.{rb,yml}')]
  Faker::Config.locale = I18n.locale
end

def init_rspec
  RSpec.configure do |config|
    config.treat_symbols_as_metadata_keys_with_true_values = true

    # ## Mock Framework
    #
    # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
    #
    # config.mock_with :mocha
    # config.mock_with :flexmock
    # config.mock_with :rr

    # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
    config.fixture_path = "#{::Rails.root}/spec/fixtures"

    # If you're not using ActiveRecord, or you'd prefer not to run each of your
    # examples within a transaction, remove the following line or assign false
    # instead of true.
    config.use_transactional_fixtures = true

    # This will pick up all of the fixtures defined in spec/fixtures into your
    # database and you'll be able to test with some sample data
    # (eg. Countries, States, etc.)
    # config.global_fixtures = :all

    # If true, the base class of anonymous controllers will be inferred
    # automatically. This will be the default behavior in future versions of
    # rspec-rails.
    config.infer_base_class_for_anonymous_controllers = false

    # Run specs in random order to surface order dependencies. If you find an
    # order dependency and want to debug it, you can fix the order by providing
    # the seed, which is printed after each run.
    #     --seed 1234
    config.order = 'random'

    config.include(MailerMacros)
    config.include(EventMacros)
    config.include Devise::TestHelpers, type: :controller
    config.include FeatureHelpers, type: :feature

    config.filter_run_excluding type: 'feature', performance: true

    if ActiveRecord::Base.connection.adapter_name.downcase != 'mysql2'
      config.filter_run_excluding :mysql
    end

    config.before :all do
      # load all fixtures
      self.class.fixtures :all
    end

    config.before(:each) do
      ActionMailer::Base.deliveries = []
    end

    config.before(:each, :draper_with_helpers) do
      c = ApplicationController.new
      c.request = ActionDispatch::TestRequest.new
      c.stub(:current_person) { people(:top_leader) }
      Draper::ViewContext.current = c.view_context
    end

    # Use DatabaseCleaner only if features are not excluded
    unless config.exclusion_filter[:type] == 'feature'
      init_db_cleaner(config)
    end
  end
end

def init_db_cleaner(config)
  config.use_transactional_fixtures = false

  config.before(:suite) do
    DatabaseCleaner.strategy = :truncation
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end

def init_capybara
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
end


if /spork/i =~ $PROGRAM_NAME || (RSpec.respond_to?(:configuration) && RSpec.configuration.drb?)
  require 'spork'
  Spork.prefork { init }
  Spork.each_run {}
else
  init
end
