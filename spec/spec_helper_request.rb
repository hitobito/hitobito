ENV['RAILS_GROUPS'] = "assets"

require 'spec_helper_base'
require 'shared_db_connection' # see https://github.com/jnicklas/capybara Transactions and db setup
require 'capybara/poltergeist'
Dir[Rails.root.join("spec/support/group/*.rb")].each {|f| require f }

RSpec.configure do |config|
  config.include RequestHelpers, type: :request
end

if ENV['HEADLESS'].blank?
  Capybara.register_driver :poltergeist do |app|
    options = { debug: false, inspector: true, timeout: 10 } 
    driver = Capybara::Poltergeist::Driver.new(app, options)
  end
  Capybara.javascript_driver = :poltergeist
end