source 'https://rubygems.org'

gem 'rails', '3.2.8'


gem 'awesome_nested_set'
gem 'bcrypt-ruby'
gem 'cancan'
#gem 'delayed_job_active_record'
gem 'devise'
gem 'haml'
gem 'hoptoad_notifier'
gem 'kaminari'
gem 'paranoia'
gem 'pg'
gem 'protective'
gem 'rails_config'
gem 'rails-i18n'
gem 'schema_validations'
gem 'seed-fu'
gem 'simple_form'


# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'bootstrap-sass'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'compass', '>= 0.13.alpha.0'
  gem 'compass-rails', '~> 1.0.2'
  gem 'jquery-rails'
  gem 'sass-rails',   '~> 3.2.3'
  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  gem 'therubyracer', :platforms => :ruby
  gem 'uglifier', '>= 1.0.3'
end

group :development, :test do
  gem 'brakeman'
  gem 'ci_reporter'
  gem 'debugger'
  gem 'faker'
  gem 'metrical' 
  gem 'rails_code_qa'
  gem 'rails_best_practices'
  gem 'rspec-rails'
  gem 'sqlite3'
end

group :development do
  gem 'annotate'
  gem 'awesome_print'
  gem 'bullet'
  gem 'hirb'
  gem 'quiet_assets'
  gem 'rails-erd'
  gem 'wirble'
  gem 'pry-rails'
  gem 'pry', require: false
  gem 'pry-doc', require: false
  gem 'pry-nav', require:false
  gem 'pry-stack_explorer'
  gem 'wagons'
  gem 'sextant'
  gem 'rack-mini-profiler'
end

group :test do
  gem 'capybara'
  gem 'database_cleaner'
  gem 'fabrication'
  gem 'headless'
  gem 'launchy'
  gem 'guard-rspec'
  gem 'guard-spork'
  gem 'simplecov-rcov'
  gem 'spork'
end

# Load all wagons found in vendor/wagons/*
group :development, :production do
    Dir[File.expand_path('../vendor/wagons/**/*.gemspec', __FILE__)].each do |spec|
        gem File.basename(spec, '.gemspec'), :path => File.expand_path('..', spec)
    end
end
