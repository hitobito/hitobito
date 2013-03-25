# Configure Rails Environment
ENV['APP_ROOT'] ||= File.expand_path(__FILE__).split("vendor#{File::SEPARATOR}wagons").first
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)
ENV["RAILS_ENV"] = "test"
require File.expand_path('../../../../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  self.reset_fixture_path File.expand_path("../../spec/fixtures", __FILE__)
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all

end
