# frozen_string_literal: true

#  Copyright (c) 2012-2022, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

source 'https://rubygems.org'

gem 'rails', '= 6.1.7.7'
gem 'wagons', '0.6.1'

gem 'activerecord-session_store'
gem 'acts-as-taggable-on'
gem 'airbrake'
gem 'awesome_nested_set'
gem 'aws-sdk-s3', require: false
gem 'bcrypt'
gem 'bleib', '~> 0.0.10'
gem 'bootsnap', require: false
gem 'cancancan', '< 3.2.0'
gem 'caxlsx'
gem 'charlock_holmes', '~> 0.7.7'
gem 'commonmarker'
gem 'config'
gem 'country_select'
gem 'csv-safe'
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
gem 'dry-validation'
gem 'epics' # client for EBICS-connections to banks
gem 'faker'
gem 'faraday'
gem 'gibbon', '~> 3.4'
gem 'globalize'
gem 'graphiti'
gem 'graphiti-rails', '~> 0.1'
gem 'haml'
gem 'http_accept_language'
gem 'icalendar'
gem 'image_processing', '~> 1.12'
gem 'lograge'
gem 'lograge_activejob'
gem 'lograge-sql'
gem 'magiclabs-userstamp', require: 'userstamp'
gem 'mail' # add mail here to have it loaded
gem 'mime-types'
gem 'mini_magick'
gem 'mysql2'
gem 'nested_form'
gem 'nokogiri'
gem 'oat'
gem 'paper_trail'
gem 'paranoia'
gem 'phonelib'
gem 'prawn'
gem 'prawn-markup'
gem 'prawn-table'
gem 'prometheus_exporter'
gem 'protective'
gem 'pry-rails'
gem 'puma'
gem 'rack-cors'
gem 'rack-mini-profiler', require: false
gem 'rails_autolink'
gem 'rails-i18n'
gem 'remotipart'
gem 'rest-client'
gem 'rexml'
gem 'rotp'
gem 'rqrcode'
gem 'rswag-api', '~> 2.13'
gem 'rswag-ui', '~> 2.13'
gem 'rubyzip'
gem 'seed-fu'
gem 'sentry-raven'
gem 'simpleidn'
gem 'simple_xlsx_reader' # import data from xlsx files (used in some wagons)
gem 'sorted_set'
gem 'sprockets', '~> 3.7.2' # pinned to older version to avoid having an empty manifest.js
gem 'sqlite3' # required for asset generation
gem 'strip_attributes' # strip whitespace of attributes
gem 'thinking-sphinx'
gem 'truemail'
gem 'turbo-rails'
gem 'validates_by_schema', '~> 0.3.0' # 0.5.1 does not work well with wagons / wagon-migrations
gem 'validates_timeliness'
gem 'vcard'
gem 'view_component'
gem 'webpacker'

# load after others because dependencies
gem 'graphiti-openapi', github: 'puzzle/graphiti-openapi', tag: 'standalone/0.2'
gem 'kaminari'

gem 'active_storage_validations' # validate filesize, dimensions and content-type of uploads
gem 'active_storage_variant' # variants for Rails < 7

group :development, :test do
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'codez-tarantula', require: 'tarantula-rails3'
  gem 'graphiti_spec_helpers'
  gem 'parallel_tests'
  gem 'pry-byebug'
  gem 'pry-doc' # provides show-source/$ in the pry-console
  gem 'rspec-rails', '~> 6.0'
end

group :development do
  gem 'bullet'
  gem 'listen'
  gem 'redcarpet'
  gem 'request_profiler'
  gem 'spring-commands-rspec'
end

group :test do
  gem 'capybara'
  gem 'capybara-screenshot'
  gem 'cmdparse'
  gem 'database_cleaner'
  gem 'fabrication'
  gem 'headless'
  gem 'launchy'
  gem 'pdf-inspector', require: 'pdf/inspector'
  gem 'rails-controller-testing'
  gem 'rspec-collection_matchers'
  gem 'rspec-its'
  gem 'selenium-devtools'
  gem 'stackprof'
  gem 'test-prof'
  gem 'webmock'
end

group :console do
  gem 'amazing_print'
  gem 'hirb'
  gem 'pry-remote'
  gem 'pry-stack_explorer'
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
