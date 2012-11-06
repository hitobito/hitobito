source 'https://rubygems.org'

gem 'rails', '3.2.8'


gem 'awesome_nested_set'
gem 'bcrypt-ruby'
gem 'cancan'
gem 'delayed_job_active_record'
gem 'decorates_before_rendering', '0.0.3'
gem 'devise'
gem 'draper'
gem 'faker'
gem 'haml'
gem 'hoptoad_notifier'
gem 'kaminari'
gem 'nested_form'
gem 'paranoia'
gem 'mysql2'
gem 'protective'
gem 'rails_config'
gem 'rails-i18n'
gem 'schema_validations'
gem 'seed-fu'
gem 'wagons'
# Remove once errbit is running again
gem 'exception_notification'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'bootstrap-sass'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'compass', '>= 0.13.alpha.0'
  gem 'compass-rails', '~> 1.0.2'
  gem 'jquery-rails'
  gem 'sass-rails', '~> 3.2.3'
  gem 'therubyracer', :platforms => :ruby
  gem 'uglifier', '>= 1.0.3'
end

group :development, :test do
  gem 'debugger'
  gem 'rspec-rails'
  gem 'sqlite3'
end

group :development do
  gem 'bullet'
  gem 'quiet_assets'
  gem 'sextant'
  gem 'rack-mini-profiler'
end

group :test do
  gem 'capybara'
  gem 'database_cleaner'
  gem 'fabrication'
  gem 'headless'
  gem 'launchy'
  gem 'poltergeist'
end

group :console do
  gem 'awesome_print'
  gem 'hirb'
  gem 'wirble'
  gem 'pry-rails'
  gem 'pry'
  gem 'pry-doc'
  gem 'pry-nav'
  gem 'pry-stack_explorer'
  gem 'mailcatcher'
  gem 'rdoc-tags'
end

group :guard do
  gem 'guard-rspec'
  gem 'guard-spork'
  gem 'spork', '1.0.0rc3'
  gem 'rb-inotify'
end

group :metrics do
  gem 'annotate'
  gem 'metrical' 
  gem 'brakeman'
  gem 'ci_reporter'
  gem 'rails_code_qa'
  gem 'rails_best_practices'
  gem 'rails-erd'
  gem 'simplecov-rcov'
end

# Load all wagons found in vendor/wagons/*
group :development, :production do
    Dir[File.expand_path('../vendor/wagons/**/*.gemspec', __FILE__)].each do |spec|
        gem File.basename(spec, '.gemspec'), :path => File.expand_path('..', spec)
    end
end
