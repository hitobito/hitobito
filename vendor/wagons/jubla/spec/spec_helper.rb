# Configure Rails Environment
ENV['APP_ROOT'] ||= File.expand_path(__FILE__).split("vendor#{File::SEPARATOR}wagons").first
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

require File.join(ENV["APP_ROOT"], 'spec', 'spec_helper.rb')


RSpec.configure do |config|
  config.fixture_path = File.expand_path("../fixtures", __FILE__)
end