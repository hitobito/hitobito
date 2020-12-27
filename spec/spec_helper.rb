#  Copyright (c) 2012-2019, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

DB_CLEANER_STRATEGY = :truncation

ENV['RAILS_ENV'] = 'test'
ENV['RAILS_GROUPS'] = 'assets'
require File.expand_path('../../config/environment', __FILE__)
require 'rspec/rails'
require 'cancan/matchers'
require 'paper_trail/frameworks/rspec'
require 'webmock/rspec'

# Needed for feature specs
WebMock.disable_net_connect!(allow_localhost: true, allow: %w(chromedriver.storage.googleapis.com))


ActiveRecord::Migration.maintain_test_schema!

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join('spec', 'support', '**', '*.rb')].sort.each { |f| require f }

# Add test locales
Faker::Config.locale = I18n.locale

RSpec.configure do |config|

  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'

  config.backtrace_exclusion_patterns = [/lib\/rspec/]
  config.example_status_persistence_file_path = Rails.root.join('tmp', 'examples.txt').to_s

  config.include(MailerMacros)
  config.include(EventMacros)
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include FeatureHelpers, type: :feature
  config.include Warden::Test::Helpers, type: :feature

  config.filter_run_excluding type: 'feature', performance: true
  config.filter_run_excluding type: 'sphinx', sphinx: true

  if ActiveRecord::Base.connection.adapter_name.downcase != 'mysql2' # rubocop:disable Performance/Casecmp
    config.filter_run_excluding :mysql
  end

  config.before :all do
    # load all fixtures
    self.class.fixtures :all
    FileUtils.rm_rf(Dir.glob(AsyncDownloadFile::DIRECTORY.join('*')))
  end

  config.before(:each) do
    ActionMailer::Base.deliveries = []
    Person.stamper = nil
  end

  config.before(:each, :draper_with_helpers) do
    c = ApplicationController.new
    c.request = ActionDispatch::TestRequest.new({})
    allow(c).to receive(:current_person) { people(:top_leader) }
    Draper::ViewContext.current = c.view_context
  end

  config.before(:each,  file_path: %r{\bspec/views/}) do
    view.extend(FormHelper,
                TableHelper,
                UtilityHelper,
                I18nHelper,
                FormatHelper,
                LayoutHelper,
                SheetHelper,
                PeopleHelper,
                EventParticipationsHelper,
                TableDisplaysHelper,
                EventKindsHelper,
                ActionHelper,
                InvoicesHelper,
                ContactableHelper)
  end

  config.around(:each, js: true) do |example|
    keeping_stdout do
      example.run
    end
  end

  config.around(:each, profile: true) do |example|
    require 'ruby-prof'

    # Profile the code
    result = RubyProf.profile { example.run }

    # Print a graph profile to text
    dir = Rails.root.join('tmp', 'performance')
    filename = File.join(dir, "#{example.metadata[:full_description]} stack.html")
    FileUtils.mkdir_p(dir)
    printer = RubyProf::CallStackPrinter.new(result)
    printer.print(File.open(filename, 'w'))
  end

  RSpec.configure do |config|
    config.include ActiveSupport::Testing::TimeHelpers
  end

  unless RSpec.configuration.exclusion_filter[:type] == 'feature'
    config.include Warden::Test::Helpers
    Warden.test_mode!

    config.use_transactional_fixtures = true
  end

  config.before { allow(Truemail).to receive(:valid?).and_return(true) }
end

# Use Capybara only if features are not excluded
unless RSpec.configuration.exclusion_filter[:type] == 'feature'
  require 'capybara'
  require 'webdrivers/chromedriver'

  Capybara.server_port = ENV['CAPYBARA_SERVER_PORT'].to_i if ENV['CAPYBARA_SERVER_PORT']
  Capybara.default_max_wait_time = 6
  Capybara.automatic_label_click = true

  require 'capybara-screenshot/rspec'
  Capybara::Screenshot.prune_strategy = :keep_last_run
  Capybara::Screenshot::RSpec::REPORTERS['RSpec::Core::Formatters::ProgressFormatter'] =
    CapybaraScreenshotPlainTextReporter


  Capybara.register_driver :chrome do |app|
    options = Selenium::WebDriver::Chrome::Options.new
    options.args << '--headless' if ENV['HEADLESS'] != 'false'
    options.args << '--disable-gpu' # required for windows
    options.args << '--no-sandbox' # required for docker
    options.args << '--disable-dev-shm-usage' # helps with docker resource limitations
    options.args << '--window-size=1800,1000'
    options.args << '--crash-dumps-dir=/tmp'
    Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
  end

  Capybara.current_driver = :chrome
  Capybara.javascript_driver = :chrome

  puts "Using chromedriver version #{Webdrivers::Chromedriver.current_version}"
end
