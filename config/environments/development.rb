# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

Hitobito::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  config.eager_load = false

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.default_url_options = {
    host: 'localhost:3000',
    protocol: (%w(true yes 1).include?(ENV['RAILS_HOST_SSL']) ? 'https' : 'http'),
    locale: nil }

  # Mail sender
  config.action_mailer.delivery_method = (ENV['RAILS_MAIL_DELIVERY_METHOD'].presence || :smtp).to_sym

  if ENV['RAILS_MAIL_DELIVERY_CONFIG'].present?
    case config.action_mailer.delivery_method.to_s
    when 'smtp'
      config.action_mailer.smtp_settings =
        YAML.load("{ #{ENV['RAILS_MAIL_DELIVERY_CONFIG']} }").symbolize_keys
    when 'sendmail'
      config.action_mailer.sendmail_settings =
        YAML.load("{ #{ENV['RAILS_MAIL_DELIVERY_CONFIG']} }").symbolize_keys
    end
  else
    # mailcatcher
    config.action_mailer.smtp_settings = { :address => "localhost", :port => 1025 }
  end

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  # Do not compress assets
  config.assets.compress = false

  # Expands the lines which load the assets
  config.assets.debug = true

  config.middleware.use "Rack::RequestProfiler", printer: RubyProf::CallStackPrinter

end
