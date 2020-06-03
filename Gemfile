# frozen_string_literal: true

#  Copyright (c) 2012-2020, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

source 'https://rubygems.org'

gem 'rails', '= 6.0.3.1'

gem 'activerecord-session_store'
gem 'acts-as-taggable-on'
gem 'airbrake'
gem 'awesome_nested_set'
gem 'axlsx', '>= 3.0.0.pre'
gem 'bcrypt'
gem 'bleib', '~> 0.0.10'
gem 'bootsnap', require: false
gem 'cancancan'
gem 'carrierwave'
gem 'cmess'
gem 'config'
gem 'country_select'
gem 'daemons'
gem 'dalli'
gem 'delayed_job_active_record'
gem 'delayed_job_heartbeat_plugin'
gem 'devise'
gem 'doorkeeper'
gem 'doorkeeper-i18n'
gem 'doorkeeper-openid_connect'
gem 'draper'
gem 'draper-cancancan'
gem 'faker'
gem 'gibbon', '~> 3.2'
gem 'globalize'
gem 'haml'
gem 'http_accept_language'
gem 'icalendar'
gem 'lograge'
gem 'lograge-sql'
gem 'lograge_activejob'
gem 'magiclabs-userstamp', require: 'userstamp'
gem 'mime-types'
gem 'mini_magick'
gem 'mysql2', '0.4.9'
gem 'nested_form'
gem 'nokogiri'
gem 'oat'
gem 'paper_trail'
gem 'paranoia'
gem 'phonelib'
gem 'prawn'
gem 'prawn-table'
gem 'prometheus_exporter'
gem 'protective'
gem 'pry-rails'
gem 'puma'
gem 'rails-i18n'
gem 'rails_autolink'
gem 'rubyzip', '~> 1.3.0'
gem 'seed-fu'
gem 'sentry-raven'
gem 'simpleidn'
gem 'sqlite3' # for development, test and production when generating assets
gem 'rqrcode'
gem 'thinking-sphinx'
gem 'validates_by_schema'
gem 'validates_timeliness', '< 4.0'
gem 'vcard'
gem 'wagons', '0.6.1'

# load after others because of active record inherited alias chain.
gem 'kaminari'

# Gems used only for assets
gem 'bootstrap-sass', '~> 2.3'
gem 'bootstrap-wysihtml5-rails'
gem 'chosen-rails'
gem 'coffee-rails'
gem 'compass'
gem 'compass-rails'
gem 'font_awesome5_rails'
gem 'jquery-rails'
gem 'jquery-turbolinks'
gem 'jquery-ui-rails'
gem 'js_cookie_rails'
gem 'remotipart'
gem 'sass-rails'
gem 'therubyracer', platforms: :ruby
gem 'turbolinks'
gem 'uglifier'

group :development, :test do
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'codez-tarantula', require: 'tarantula-rails3'
  gem 'parallel_tests'
  gem 'pry-byebug'
  gem 'pry-doc'
  gem 'rspec-rails', '4.0.0.beta3' # see https://github.com/rspec/rspec-rails/issues/2177
end

group :development do
  gem 'bullet'
  gem 'listen'
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
  gem 'rails-controller-testing'
  gem 'rspec-collection_matchers'
  gem 'rspec-its'
  gem 'selenium-webdriver'
  gem 'webdrivers'
  gem 'webmock'
end

group :console do
  gem 'awesome_print'
  gem 'hirb'
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
  gem 'rubocop-rails'
  gem 'ruby-prof'
end

# Include the wagon gems you want attached in Wagonfile.
# Do not check Wagonfile into source control.
#
# To create a Wagonfile suitable for development, run 'rake wagon:file'
wagonfile = File.expand_path('Wagonfile', __dir__)
eval(File.read(wagonfile)) if File.exist?(wagonfile) # rubocop:disable Security/Eval
