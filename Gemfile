source 'https://rubygems.org'

gem 'rails', '4.0.5'

gem 'activerecord-session_store'
gem 'airbrake'
gem 'awesome_nested_set', '>= 3.0.0.rc.3'
gem 'bcrypt-ruby'
gem 'cancancan'
gem 'carrierwave'
gem 'cmess'
gem 'daemons'
gem 'dalli'
gem 'delayed_job_active_record'
gem 'devise'
gem 'draper'
gem 'faker'
gem 'globalize'
gem 'haml'
gem 'http_accept_language'
gem 'magiclabs-userstamp', require: 'userstamp'
gem 'mini_magick'
gem 'mysql2'
gem 'nested_form'
gem 'paper_trail'
gem 'paranoia'
gem 'prawn'
gem 'protective'
gem 'rack'
gem 'rails_config'
gem 'rails-i18n'
gem 'schema_validations'
gem 'seed-fu'
gem 'thinking-sphinx'
gem 'validates_timeliness'
gem 'wagons'

# load after others because of active record inherited alias chain.
gem 'kaminari'

# Gems used only for assets
gem 'bootstrap-sass', '~> 2.3'
gem 'bootstrap-wysihtml5-rails'
gem 'chosen-rails'
gem 'coffee-rails'
gem 'compass'
gem 'compass-rails', '>= 1.1.7'
gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'sass-rails'
gem 'therubyracer', :platforms => :ruby
gem 'uglifier'

group :development, :test do
  gem 'binding_of_caller'
  gem 'rspec-rails'
  gem 'rspec-core'
  gem 'sqlite3'
  gem 'codez-tarantula', require: 'tarantula-rails3'
end

group :development do
  gem 'better_errors'
  gem 'bullet'
  gem 'quiet_assets'
end

group :test do
  gem 'capybara'
  gem 'database_cleaner'
  gem 'fabrication'
  gem 'headless'
  gem 'launchy'
  gem 'poltergeist'
  gem 'rspec-notify-osd'
  gem 'selenium-webdriver'
  gem 'websocket-driver'
end

group :console do
  gem 'awesome_print'
  gem 'debugger'
  gem 'hirb'
  gem 'mailcatcher'
  gem 'pry'
  gem 'pry-doc'
  gem 'pry-nav'
  gem 'pry-rails'
  #gem 'pry-stack_explorer'
  gem 'rdoc-tags'
  gem 'spring-commands-rspec'
  gem 'wirble'
  gem 'zeus'
end

group :guard_support do
  gem 'guard-rspec'
  gem 'guard-spork'
  gem 'rb-inotify'
  gem 'spork', '~> 1.0.0rc3'
end

group :metrics do
  gem 'annotate'
  gem 'brakeman', '2.5.0'
  gem 'ci_reporter'
  gem 'rails_code_qa'
  gem 'rails_best_practices'
  gem 'rails-erd'
  gem 'rubocop'
  gem 'rubocop-checkstyle_formatter'
  gem 'ruby-prof'
  gem 'simplecov-rcov'
end

# Include the wagon gems you want attached in Wagonfile.
# Do not check Wagonfile into source control.
#
# To create a Wagonfile suitable for development, run 'rake wagon:file'
wagonfile = File.expand_path('../Wagonfile', __FILE__)
eval(File.read(wagonfile)) if File.exist?(wagonfile)
