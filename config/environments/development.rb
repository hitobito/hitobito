Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded any time
  # it changes. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.enable_reloading = true

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

    if ENV["IS_DOCKER_DEV_ENV"] == "1"
      BetterErrors::Middleware.allow_ip!("172.0.0.0/8")
    end

  # Enable server timing
  config.server_timing = true

  # Enable/disable caching. By default caching is disabled.
  # Run rails dev:cache to toggle caching.
  if Rails.root.join("tmp/caching-dev.txt").exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true

    config.cache_store = :memory_store
    config.public_file_server.headers = {
      "Cache-Control" => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  # Store uploaded files on the local file system by default (see config/storage.yml for options).
  config.active_storage.service = ENV.fetch('RAILS_STORAGE_SERVICE', 'local').to_sym

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  config.action_mailer.perform_caching = false

  if ENV['RAILS_MAIL_DELIVERY_CONFIG'].present?
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings =
        YAML.load("{ #{ENV['RAILS_MAIL_DELIVERY_CONFIG']} }").symbolize_keys
  end

  url_options = {
    host: ENV.fetch('RAILS_HOST_NAME', 'localhost:3000'),
    locale: nil,
  }
  config.action_mailer.default_url_options = url_options
  config.action_mailer.asset_host = "http://#{url_options[:host]}"

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Highlight code that enqueued background job in logs.
  config.active_job.verbose_enqueue_logs = true

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Raises error for missing translations.
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker
  config.i18n.raise_on_missing_translations = true

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker

  config.hosts.clear

  config.after_initialize do
    ActiveRecord::Base.logger = nil if ENV["RAILS_SILENCE_ACTIVE_RECORD"] == "1"
  end

  # config.action_cable.disable_request_forgery_protection = true

  routes.default_url_options[:host] = 'localhost:3000'
end
