ENV['RAILS_GROUPS'] = "assets"

require 'spec_helper_base'
require 'shared_db_connection' # see https://github.com/jnicklas/capybara Transactions and db setup
#Dir[Rails.root.join("spec/support/group/*.rb")].each {|f| require f }

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
  require 'capybara/poltergeist'
  Capybara.register_driver :poltergeist do |app|
    options = { debug: false, inspector: true, timeout: 10 } 
    driver = Capybara::Poltergeist::Driver.new(app, options)
  end
  Capybara.javascript_driver = :poltergeist
end