#  Copyright (c) 2012-2024, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot for better performance and memory savings (ignored by Rake tasks).
  config.eager_load = true

  # Full error reports are disabled.
  config.consider_all_requests_local = false

  # Turn on fragment caching in view templates.
  config.action_controller.perform_caching = true

  # Disable serving static files from `public/`, relying on NGINX/Apache to do so instead.
  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?

  # Cache assets for far-future expiry since they are all digest stamped.
  #config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }

  # Do not fall back to assets pipeline if a precompiled asset is missed.
  config.assets.compile = false

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = "http://assets.example.com"

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = ENV.fetch('RAILS_STORAGE_SERVICE', 'local').to_sym

  # Assume all access to the app is happening through a SSL-terminating reverse proxy.
  # config.assume_ssl = true

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  ssl = %w(true yes 1).include?(ENV['RAILS_HOST_SSL'])
  config.force_ssl = ssl
  config.ssl_options = {
    redirect: { exclude: ->(request) { request.path =~ /healthz/ } }
  }

  # Skip http-to-https redirect for the default health check endpoint.
  # config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }

  # Log to STDOUT with the current request id as a default log tag.
  #config.log_tags = [ :request_id ]
  #config.logger   = ActiveSupport::TaggedLogging.logger(STDOUT)

  # Change to "debug" to log everything (including potentially personally-identifiable information!)
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Prevent health checks from clogging up the logs.
  #config.silence_healthcheck_path = "/up"

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Replace the default in-process memory cache store with a durable alternative.
  # config.cache_store = :mem_cache_store

  # Replace the default in-process and non-durable queuing backend for Active Job.
  # config.active_job.queue_adapter = :resque
  # config.active_job.queue_name_prefix = "hitobito_production"

  # Disable caching for Action Mailer templates even if Action Controller
  # caching is enabled.
  config.action_mailer.perform_caching = false

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  url_options = {
    host: (ENV['RAILS_HOST_NAME'] || raise("No environment variable RAILS_HOST_NAME set!")),
    protocol: (ssl ? 'https' : 'http'),
    locale: nil
  }

  # Set host to be used by links generated in mailer templates.
  config.action_mailer.default_url_options = url_options
  config.action_mailer.asset_host = "#{url_options[:protocol]}://#{url_options[:host]}"

 # Mail sender
  config.action_mailer.delivery_method = (ENV['RAILS_MAIL_DELIVERY_METHOD'].presence || :smtp).to_sym

  if ENV['RAILS_MAIL_DELIVERY_CONFIG'].present?
    case config.action_mailer.delivery_method
    when :smtp
      config.action_mailer.smtp_settings =
        YAML.load("{ #{ENV['RAILS_MAIL_DELIVERY_CONFIG']} }").symbolize_keys
    when :sendmail
      config.action_mailer.sendmail_settings =
        YAML.load("{ #{ENV['RAILS_MAIL_DELIVERY_CONFIG']} }").symbolize_keys
    end
  end

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  # config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners.
  config.active_support.deprecation = :notify

  # Use default logging formatter so that PID and timestamp are not suppressed.
  config.log_formatter = ::Logger::Formatter.new

  config.lograge.enabled = true
  # Use a different logger for distributed setups.
  # require "syslog/logger"
  # config.logger = ActiveSupport::TaggedLogging.new(Syslog::Logger.new "app-name")

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Only use :id for inspections in production.
  #config.active_record.attributes_for_inspect = [ :id ]

  # Enable DNS rebinding protection and other `Host` header attacks.
  # config.hosts = [
  #   "example.com",     # Allow requests from example.com
  #   /.*\.example\.com/ # Allow requests from subdomains like `www.example.com`
  # ]
  #
  # Skip DNS rebinding protection for the default health check endpoint.
  # config.host_authorization = { exclude: ->(request) { request.path == "/up" } }

  config.hosts << ENV["RAILS_HOST_NAME"]
  config.hosts << ENV["RAILS_HOST_NAME_INTERNAL"] if ENV.key?('RAILS_HOST_NAME_INTERNAL')
  config.hosts << Regexp.new(ENV["RAILS_HOST_REGEX"], Regexp::IGNORECASE) if ENV.key?('RAILS_HOST_REGEX')
  config.hosts << ENV["LIVENESS_IP_ADDRESS"]
end
