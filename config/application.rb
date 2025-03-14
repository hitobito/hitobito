require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
# require "action_mailbox/engine"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Hitobito
  def self.logger
    @logger ||= HitobitoLogger.new
  end

  def self.localized_email_sender
    I18n.t("settings.email.sender", default: Settings.email.sender, mail_domain: Settings.email.list_domain)
  end

  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Changing this default means that all new cache entries added to the cache
    # will have a different format that is not supported by Rails 7.0
    # applications.
    # INFO: New version means we have to restart `memcached` after deployment
    config.active_support.cache_format_version = 7.1

    config.active_record.raise_on_assign_to_attr_readonly = false

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
    config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # Define which locales from the rails-i18n gem should be loaded
    config.i18n.available_locales = [:de, :fr, :it, :en] # en required for faker (seeds)
    config.i18n.default_locale = :en
    config.i18n.locale = :en # required to always have default_locale used if nothing else is set.
    # All languages should fall back on each other to avoid empty attributes
    # if an entry is created in a different language.
    # This is read by globalize as well
    config.i18n.fallbacks = [:en,
    {
      de: [:de, :fr, :it, :en],
      fr: [:fr, :it, :en, :de],
      it: [:it, :fr, :en, :de],
      en: [:en, :de, :fr, :it]
    }]
    I18n.config.enforce_available_locales = true

    # Route errors over the Rails application.
    config.exceptions_app = self.routes

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password, :user_token]

    # Enable escaping HTML in JSON.
    config.active_support.escape_html_entities_in_json = true

    config.active_record.time_zone_aware_types = [:datetime, :time]

    # Deviate from default here for now, revisit later
    config.active_record.belongs_to_required_by_default = false
    config.action_controller.per_form_csrf_tokens = true

    # ActiveJob is only used to deliver emails in the background (`deliver_later`).
    # Otherwise, we use Delayed Job directly with jobs inheriting from our `BaseJob`.
    config.active_job.queue_adapter = :delayed_job

    config.after_initialize do
      ActiveRecord.yaml_column_permitted_classes += [
        Array,
        Symbol,
        Date,
        Time,
        ActiveSupport::HashWithIndifferentAccess,
        ActiveSupport::TimeWithZone,
        ActiveSupport::TimeZone,
        ActionController::Parameters,
        Person::Filter::Chain,
        Person::Filter::Role,
        BigDecimal
      ]
    end

    config.middleware.insert_before Rack::ETag, Rack::Deflater

    config.cache_store = :mem_cache_store, { compress: true,
                                             namespace: ENV['RAILS_HOST_NAME'] || 'hitobito' }

    config.active_storage.variant_processor = :vips

    config.debug_exception_response_format = :api

    if ENV["RAILS_LOG_TO_STDOUT"].present? && !Rails.env.test?
      logger = ActiveSupport::Logger.new(STDOUT)
      logger.formatter = config.log_formatter
      config.logger = ActiveSupport::TaggedLogging.new(logger)
    end

    config.responders.error_status = :unprocessable_entity
    config.responders.redirect_status = :see_other

    config.generators do |g|
      g.test_framework :rspec, fixture: true
    end

    config.to_prepare do
      ActionMailer::Base.default from: Settings.email.sender
    end
    config.action_mailer.deliver_later_queue_name = 'mailers'

    def self.versions(file = Rails.root.join('WAGON_VERSIONS'))
      @versions ||= {}
      @versions[file] ||= (file.exist? ? file.read.lines.reject(&:blank?) : nil)
      @versions[file].to_a
    end

    def self.build_info
      @build_info ||= File.read("#{Rails.root}/BUILD_INFO").strip rescue ''
    end
  end
end

# PDF's built-in fonts have very limited support for internationalized text.
# If you need full UTF-8 support, consider using an external font instead.
# To disable this warning, add the following line to your code:
# Prawn::Fonts::AFM.hide_m17n_warning = true
Prawn::Fonts::AFM.hide_m17n_warning = true
require 'prawn/measurement_extensions'
