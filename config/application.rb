# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require File.expand_path('../boot', __FILE__)

def with_benchmark(tag, &block)
  if ENV['RAILS_ENV'] == 'production'
    yield
  else
    require 'benchmark'
    puts "require #{tag}: #{Benchmark.measure(&block)}"
  end
end

with_benchmark('rails') do
  require 'rails/all'
end
with_benchmark('gems') do
  require 'jquery/rails'
  Bundler.require(:default, Rails.env)
end

module Hitobito
  class Application < Rails::Application

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    config.autoload_paths += %W( #{config.root}/app/abilities
                                 #{config.root}/app/domain
                                 #{config.root}/app/jobs
                                 #{config.root}/app/serializers
                                 #{config.root}/app/utils
                             )

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'
    config.time_zone = 'Bern'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # Define which locales from the rails-i18n gem should be loaded
    config.i18n.available_locales = [:de, :fr, :it, :en] # en required for faker (seeds)
    config.i18n.default_locale = :de
    config.i18n.locale = :de # required to always have default_locale used if nothing else is set.
    config.i18n.fallbacks = [:de]
    I18n.config.enforce_available_locales = true
    # All languages should fall back on each other to avoid empty attributes
    # if an entry is created in a different language.
    Globalize.fallbacks = { de: [:de, :fr, :it, :en],
                            fr: [:fr, :it, :en, :de],
                            it: [:it, :fr, :en, :de],
                            en: [:en, :de, :fr, :it] }

    # Route errors over the Rails application.
    config.exceptions_app = self.routes

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = 'utf-8'

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password, :user_token]

    # Enable escaping HTML in JSON.
    config.active_support.escape_html_entities_in_json = true

    config.active_record.raise_in_transactional_callbacks = true

    config.active_job.queue_adapter = :delayed_job

    config.middleware.insert_before Rack::ETag, Rack::Deflater


    config.log_tags = [:uuid]

    config.cache_store = :dalli_store, { compress: true,
                                         namespace: ENV['RAILS_HOST_NAME'] || 'hitobito' }

    # Enable the asset pipeline
    config.assets.enabled = true

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'

    config.assets.precompile += %w(print.css ie.css ie7.css wysiwyg.css wysiwyg.js
                                   *.png *.gif *.jpg favicon.ico)

    config.generators do |g|
      g.test_framework :rspec, fixture: true
    end

    config.to_prepare do
      ActionMailer::Base.default from: Settings.email.sender

      # Assert the mail relay job is scheduled on every restart.
      if Delayed::Job.table_exists?
        MailRelayJob.new.schedule if Settings.email.retriever.config.present?
        SphinxIndexJob.new.schedule if Application.sphinx_present? && Application.sphinx_local?
        DownloadCleanerJob.new.schedule
        SessionsCleanerJob.new.schedule
      end
    end

    initializer :define_sphinx_indizes, before: :add_to_prepare_blocks do |app|
      # only add here to be the last one
      app.config.to_prepare do
        ThinkingSphinx::Index.define_partial_indizes!
      end
    end

    def self.sphinx_version
      @sphinx_version ||= ThinkingSphinx::Configuration.instance.controller.sphinx_version.presence ||
        ENV['RAILS_SPHINX_VERSION']
    end

    def self.sphinx_present?
      port = ENV['RAILS_SPHINX_PORT']
      port.present? || ThinkingSphinx::Configuration.instance.controller.running?
    end

    def self.sphinx_local?
      host = ENV['RAILS_SPHINX_HOST']
      host.blank? || host == '127.0.0.1' || host == 'localhost'
    end

    def self.versions(file = Rails.root.join('WAGON_VERSIONS'))
      @versions ||= file.exist? ? file.read.lines.reject(&:blank?) : []
    end

    def self.build_info
      @build_info ||= File.read("#{Rails.root}/BUILD_INFO").strip rescue ''
    end

  end
end

require 'prawn/measurement_extensions'
