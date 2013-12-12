source 'https://rubygems.org'

gem 'rails', '3.2.16'

gem 'airbrake'
gem 'awesome_nested_set'
gem 'bcrypt-ruby'
gem 'cancan'
gem 'carrierwave'
gem 'cmess'
gem 'daemons'
gem 'dalli'
gem 'delayed_job_active_record'
#gem 'decorates_before_rendering', '0.0.3'
gem 'devise'
gem 'draper', '< 1.0'
gem 'faker'
gem 'haml'
gem 'kaminari'
gem 'magiclabs-userstamp', require: 'userstamp'
gem 'mini_magick'
gem 'mysql2'
gem 'nested_form'
gem 'paranoia'
gem 'prawn'
gem 'protective'
gem 'rack'
gem 'rails_config'
gem 'rails-i18n'
gem 'schema_validations'
gem 'seed-fu'
gem 'thinking-sphinx', '~> 2.1'
gem 'wagons'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'bootstrap-sass'
  gem 'bootstrap-wysihtml5-rails'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'compass', '>= 0.13.alpha.0'
  gem 'compass-rails'
  gem 'jquery-rails', '2.1.3'
  gem 'sass-rails', '~> 3.2.3'
  gem 'therubyracer', :platforms => :ruby
  gem 'uglifier'
end

group :development, :test do
  gem 'binding_of_caller'
  gem 'rspec-rails'
  gem 'sqlite3'
  gem 'codez-tarantula', require: 'tarantula-rails3'
end

group :development do
  gem 'bullet'
  gem 'quiet_assets'
  gem 'sextant'
  gem 'better_errors'
end

group :test do
  gem 'capybara', '~> 1.1'
  gem 'database_cleaner'
  gem 'fabrication'
  gem 'headless'
  gem 'launchy'
  gem 'poltergeist'
  gem 'rspec-notify-osd'
end

group :console do
  gem 'debugger'
  gem 'awesome_print'
  gem 'hirb'
  gem 'wirble'
  gem 'pry-rails'
  gem 'pry'
  gem 'pry-doc'
  gem 'pry-nav'
  #gem 'pry-stack_explorer'
  gem 'mailcatcher'
  gem 'rdoc-tags'
  gem 'zeus'
  gem 'spring-commands-rspec'
end

group :guard_support do
  gem 'guard-rspec'
  gem 'guard-spork'
  gem 'spork', '1.0.0rc3'
  gem 'rb-inotify'
end

group :metrics do
  gem 'annotate'
  gem 'brakeman'
  gem 'ci_reporter'
  gem 'rails_code_qa'
  gem 'rails_best_practices'
  gem 'rails-erd'
  gem 'simplecov-rcov'
  gem 'rubocop'
  gem 'rubocop-checkstyle_formatter'
end

# Include the wagon gems you want attached in Wagonfile.
# Do not check Wagonfile into source control.
#
# To create a Wagonfile suitable for development, run 'rake wagon:file'
wagonfile = File.expand_path('../Wagonfile', __FILE__)
eval(File.read(wagonfile)) if File.exist?(wagonfile)
