# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

source 'https://rubygems.org'

gem 'rails', '4.2.11.1'

gem 'activerecord-session_store'
gem 'acts-as-taggable-on', '~> 3.5.0'
gem 'airbrake', '< 5.0' # requires newer errbit
gem 'awesome_nested_set', '< 3.1.0' # requires ruby 2.0
gem 'axlsx', '>= 3.0.0.pre'
gem 'bcrypt-ruby'
gem 'bleib', '~> 0.0.10'
gem 'cancancan', '< 1.13.0' # requires ruby 2.0
gem 'carrierwave', '< 0.11.1' # uses 2.0 for testing (no explicit requirement, yet)
gem 'cmess'
gem 'config', '< 1.1.0' # requires ruby 2
gem 'country_select'
gem 'daemons'
gem 'dalli'
gem 'delayed_job_active_record'
gem 'devise', '>= 4.7.1'
gem 'doorkeeper'
gem 'doorkeeper-i18n'
gem 'draper'
gem 'faker', '< 1.6.4' # uses 2.0 for testing (no explicit requirement, yet)
gem 'gibbon', '~> 3.2'
gem 'globalize'
gem 'haml'
gem 'http_accept_language'
gem 'icalendar'
gem 'magiclabs-userstamp', require: 'userstamp'
gem 'mime-types', '~> 2.6.2' # newer requires ruby 2.0
gem 'mini_magick'
gem 'mysql2', '0.4.9'
gem 'nested_form'
gem 'nokogiri', '~> 1.8.2'
gem 'oat'
gem 'paper_trail'
gem 'paranoia', '< 2.1.2' # uses 2.0 for testing (no explicit requirement, yet)
gem 'prawn', '< 2.0' # 2.0 requires ruby 2.0
gem 'prawn-table'
gem 'protective'
gem 'puma'
gem 'rails-i18n'
gem 'rails_autolink'
gem 'rubyzip', '~> 1.3.0'
gem 'seed-fu'
gem 'sentry-raven'
gem 'simpleidn'
gem 'sqlite3' # for development, test and production when generating assets
gem 'thinking-sphinx'
gem 'validates_by_schema'
gem 'validates_timeliness', '< 4.0'
gem 'vcard'
gem 'wagons'

# load after others because of active record inherited alias chain.
gem 'kaminari', '< 1.0.0' # requires ruby 2.0

# Gems used only for assets
gem 'bootstrap-sass', '~> 2.3'
gem 'bootstrap-wysihtml5-rails'
gem 'chosen-rails'
gem 'coffee-rails'
gem 'compass'
gem 'compass-rails'
gem 'font-awesome-rails', '~> 4.7', '>= 4.7.0.1'
gem 'jquery-cookie-rails'
gem 'jquery-rails'
gem 'jquery-turbolinks'
gem 'jquery-ui-rails'
gem 'remotipart'
gem 'sass-rails'
gem 'therubyracer', platforms: :ruby
gem 'turbolinks'
gem 'uglifier'

# security updates, can be deleted or changed if they get in the way of updates or so
gem 'loofah', '~> 2.2.3'
gem 'rack', '~> 1.6.11'
gem 'sprockets', '~> 3.7.2'


group :development, :test do
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'codez-tarantula', require: 'tarantula-rails3'
  gem 'parallel_tests'
  gem 'pry-rails'
  gem 'rspec-rails'

  gem 'pry-debugger', platforms: :ruby_19
  gem 'pry-doc'
  # gem 'pry-byebug', platforms: [:ruby_20, :ruby_21]
end

group :development do
  gem 'bullet'
  gem 'quiet_assets'
  gem 'redcarpet'
  gem 'request_profiler'
end

group :test do
  gem 'capybara'
  gem 'capybara-screenshot'
  gem 'database_cleaner'
  gem 'fabrication'
  gem 'headless'
  gem 'launchy'
  gem 'pdf-inspector', require: 'pdf/inspector'
  gem 'rspec-collection_matchers'
  gem 'rspec-its'
  gem 'selenium-webdriver'
  gem 'webdrivers', '3.9.4'
  gem 'webmock', '~> 3.4', '>= 3.4.2'
end

group :console do
  gem 'awesome_print'
  gem 'hirb'
  gem 'mailcatcher'
  gem 'pry-remote'
  gem 'pry-stack_explorer'
  gem 'rdoc-tags'
  gem 'spring-commands-rspec'
  gem 'wirble'
end

group :metrics do
  gem 'annotate'
  gem 'brakeman'
  gem 'ci_reporter_rspec'
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
eval(File.read(wagonfile)) if File.exist?(wagonfile) # rubocop:disable Security/Eval
