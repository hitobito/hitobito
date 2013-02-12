source 'https://rubygems.org'

gem 'rails', '3.2.12'

gem 'airbrake'
gem 'awesome_nested_set'
gem 'bcrypt-ruby'
gem 'cancan'
gem 'carrierwave'
gem 'cmess'
gem 'daemons'
gem 'dalli'
gem 'delayed_job_active_record'
gem 'decorates_before_rendering', '0.0.3'
gem 'devise'
gem 'draper', '< 1.0'
gem 'faker'
gem 'haml'
gem 'kaminari'
gem "magiclabs-userstamp", require: 'userstamp'
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
gem 'thinking-sphinx', '~> 2.0'
gem 'wagons'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'bootstrap-sass'
  gem 'bootstrap-wysihtml5-rails'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'compass', '>= 0.13.alpha.0'
  gem 'compass-rails', '~> 1.0.2'
  gem 'jquery-rails', '2.1.3'
  gem 'sass-rails', '~> 3.2.3'
  gem 'therubyracer', '~> 0.10.2', :platforms => :ruby
  gem 'uglifier', '>= 1.0.3'
end

group :development, :test do
  gem 'rspec-rails'
  gem 'sqlite3'
end

group :development do
  gem 'bullet'
  gem 'quiet_assets'
  gem 'sextant'
  gem 'rack-mini-profiler'
  gem "better_errors"
end

group :test do
  gem 'capybara'
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
  gem 'pry-stack_explorer'
  gem 'mailcatcher'
  gem 'rdoc-tags'
  gem 'zeus'
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
end

# Load all wagons found in vendor/wagons/*
group :development, :production do
    Dir[File.expand_path('../vendor/wagons/**/*.gemspec', __FILE__)].each do |spec|
        gem File.basename(spec, '.gemspec'), :path => File.expand_path('..', spec)
    end
end
