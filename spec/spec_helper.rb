# frozen_string_literal: true

#  Copyright (c) 2012-2024, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

DB_CLEANER_STRATEGY = :truncation

ENV['RAILS_ENV'] = 'test'
ENV['RAILS_GROUPS'] = 'assets'
require File.expand_path('../config/environment', __dir__)
require 'rspec/rails'
require 'cancan/matchers'
require 'paper_trail/frameworks/rspec'
require 'webmock/rspec'
require 'graphiti_spec_helpers/rspec'

require 'view_component/test_helpers'
require 'view_component/system_test_helpers'

require 'test_prof/recipes/logging'

TestProf::StackProf.configure do |config|
  config.format = 'json'
end


# Needed for feature specs
WebMock.disable_net_connect!(
  allow_localhost: true,
  allow: %w(
    chromedriver.storage.googleapis.com
    storage.googleapis.com
    googlechromelabs.github.io
    edgedl.me.gvt1.com
    github.com github-releases.githubusercontent.com
  )
)

ActiveRecord::Migration.suppress_messages do
  if ActiveRecord::Base.maintain_test_schema
    begin
      previous_seed_quietness = SeedFu.quiet
      SeedFu.quiet = true

      Wagons.all.each do |wagon|
        wagon.migrate
        wagon.load_seed
      end
    ensure
      SeedFu.quiet = previous_seed_quietness
    end

    ActiveRecord::Migration.load_schema_if_pending!
  end
end

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join('spec', 'support', '**', '*.rb')].sort.each do |f|
  # Do not require the core testgroup/layer files when running in wagon
  next if f =~ %r{spec/support/group/(?!0_base.rb)} && (ENV['APP_ROOT'].present? || ENV['RAILS_USE_TEST_GROUPS'].blank?)

  require f
end

# Add test locales
Faker::Config.locale = I18n.locale

RSpec::Matchers.define_negated_matcher :not_change, :change

RSpec.configure do |config|

  config.fixture_path = Rails.root / 'spec' / 'fixtures'

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

  config.backtrace_exclusion_patterns = [/lib\/rspec/, /asdf/]
  config.example_status_persistence_file_path = Rails.root.join('tmp', 'examples.txt').to_s

  config.expect_with :rspec do |c|
    c.max_formatted_output_length = 1000
  end

  config.include MailerMacros
  config.include EventMacros
  config.include I18nHelpers
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include FeatureHelpers, type: :feature
  config.include Warden::Test::Helpers, type: :feature
  config.include ActiveSupport::Testing::TimeHelpers
  config.include ViewComponent::TestHelpers, type: :component
  config.include ViewComponent::SystemTestHelpers, type: :component
  config.include Capybara::RSpecMatchers, type: :component

  config.filter_run_excluding type: 'sphinx', sphinx: true
  if ActiveRecord::Base.connection.adapter_name.downcase != 'mysql2'
    config.filter_run_excluding :mysql
  end

  config.before :all do
    # load all fixtures
    self.class.fixtures :all
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

  config.before(:each, file_path: %r{\bspec/views/}) do
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

  # reset current locale and reload translations after example run
  config.around do |example|
    original_locale = I18n.locale
    example.call
    I18n.locale = original_locale
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

  unless RSpec.configuration.exclusion_filter[:type] == 'feature'
    config.include Warden::Test::Helpers
    Warden.test_mode!

    config.use_transactional_fixtures = true
  end

  config.before { allow(Truemail).to receive(:valid?).and_return(true) }
  config.before do
    # this job is usually enqueued when a person is created. So it makes sense to
    # prevent this in test env when using for example Fabricate
    job_double = double({ enqueue!: nil })
  end

  config.include Job::TestHelpers, :tests_active_jobs

  # graphiti
  config.include GraphitiSpecHelpers::RSpec
  config.include GraphitiSpecHelpers::Sugar
  config.include Graphiti::Rails::TestHelpers
  config.include ResourceSpecHelper, type: :resource

  config.before :each do
    handle_request_exceptions(false)
  end

  if defined?(RescueRegistry)
    # RescueRegistry.context must be reset between requests. This normally
    # happens in a standard Rails middleware.
    # We must reset it manually as most tests bypass the middleware
    config.after do
      RescueRegistry.context = nil
    end
  end

end

require 'capybara/rails'
require 'capybara-screenshot/rspec'
require 'selenium-webdriver'

Capybara.server = :puma, { Silent: true }
Capybara.server_port = ENV['CAPYBARA_SERVER_PORT'].to_i if ENV['CAPYBARA_SERVER_PORT']
Capybara.default_max_wait_time = ENV.fetch('CAPYBARA_MAX_WAIT_TIME', 6).to_f
Capybara.automatic_label_click = true

Capybara::Screenshot.prune_strategy = :keep_last_run
Capybara::Screenshot::RSpec::REPORTERS['RSpec::Core::Formatters::ProgressFormatter'] =
  CapybaraScreenshotPlainTextReporter
Capybara::Screenshot.register_driver(:chrome) do |driver, path|
  driver.browser.save_screenshot(path)
end

Capybara.register_driver :chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.args << '--headless' if ENV['HEADLESS'] != 'false'
  options.args << '--disable-gpu' # required for windows
  options.args << '--no-sandbox' # required for docker
  options.args << '--disable-dev-shm-usage' # helps with docker resource limitations
  options.args << '--window-size=1800,1000'
  options.args << '--crash-dumps-dir=/tmp'
  options.add_preference('intl.accept_languages', 'de-CH,de')
  if ENV['CAPYBARA_CHROME_BINARY'].present?
    options.add_option('binary',
                       ENV['CAPYBARA_CHROME_BINARY'])
  end
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

Capybara.current_driver = :chrome
Capybara.javascript_driver = :chrome

Devise::Test::ControllerHelpers.prepend(Module.new do
  # Make sure the email address is confirmed before logging in
  def sign_in(resource, deprecated = nil, scope: nil, confirm: true)
    resource.confirm if confirm
    super(resource, deprecated, scope: scope)
  end
end)

module ActiveRecordFixture
  def initialize(fixture, model_class)
    if model_class == Person
      fixture['confirmed_at'] = 1.day.ago unless fixture.key?('confirmed_at')
    end

    super(fixture, model_class)
  end
end
ActiveRecord::Fixture.prepend(ActiveRecordFixture)
