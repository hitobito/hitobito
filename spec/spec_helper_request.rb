ENV['RAILS_GROUPS'] = "assets"

require 'spec_helper_base'
require 'capybara/poltergeist'

RSpec.configure do |config|
  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
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


if ENV['HEADLESS'] == 'true'
  require 'headless'

  headless = Headless.new
  headless.start

  at_exit do
    headless.destroy
  end
elsif ENV['HEADLESS'] == 'false'
  # use selenium-webkit driver
else
  Capybara.register_driver :poltergeist do |app|
    options = { debug: false, inspector: true, timeout: 10 } 
    driver = Capybara::Poltergeist::Driver.new(app, options)
  end
  Capybara.javascript_driver = :poltergeist
end