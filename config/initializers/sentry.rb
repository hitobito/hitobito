# frozen_string_literal: true

#  Copyright (c) 2021-2024, Katholische Landjugendbewegung Paderborn. This file
#  is part of hitobito and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
#
#

Rails.application.reloader.to_prepare do
  Sentry.init do |config|
    config.dsn = ENV["SENTRY_DSN"]
    config.release = Rails.application.class.versions(Rails.root.join("VERSION")).first.chomp

    # send sensitive information like ip, cookie, request body and query params
    config.send_default_pii = true

    config.environment = ENV.fetch("HITOBITO_STAGE", Rails.env) if ENV["SENTRY_CURRENT_ENV"].blank?

    config.app_dirs_pattern = /(app|config|lib|db|bin|spec|vendor\/wagons)/

    setup_and_connection_errors = [
      "ActiveRecord::ConnectionNotEstablished",
      "Aws::S3::Errors::Http503Error",
      "Errno::ECONNREFUSED",
      "Errno::ECONNRESET",
      "Errno::EFAULT",
      "Errno::ENETUNREACH",
      "Errno::ENOMEM",
      "JsonApiController::JsonApiUnauthorized",
      "PG::ConnectionBad",
      "Net::OpenTimeout",
      "Net::ReadTimeout",
      "SignalException",
      "Timeout::Error"
    ]

    misbehaving_client_errors = [
      "ActionDispatch::Http::MimeNegotiation::InvalidType",
      "Rack::Multipart::EmptyContentError"
    ]

    config.excluded_exceptions += [
      *setup_and_connection_errors,
      *misbehaving_client_errors
    ]

    # Scrubbing data as recommended
    # https://docs.sentry.io/platforms/ruby/guides/rails/data-management/sensitive-data/#scrubbing-data
    filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
    config.before_send = lambda do |event, _hint|
      # Sanitize extra data
      if event.extra
        event.extra = filter.filter(event.extra)
      end

      # Sanitize user data
      if event.user
        event.user = filter.filter(event.user)
      end

      # Sanitize context data (if present)
      if event.contexts
        event.contexts = filter.filter(event.contexts)
      end

      # Add project tag
      event.tags[:project] = ENV.fetch("HITOBITO_PROJECT", "hitobito")

      # Return the sanitized event object
      event
    end
  end
end
