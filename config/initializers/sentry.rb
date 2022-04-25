# frozen_string_literal: true

#  Copyright (c) 2021-2022, Katholische Landjugendbewegung Paderborn. This file
#  is part of hitobito and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

Raven.configure do |config|
  config.sanitize_fields = Rails.application.config.filter_parameters.map(&:to_s)

  config.release = Rails.application.class.versions(Rails.root.join('VERSION')).first.chomp

  if ENV['SENTRY_CURRENT_ENV'].blank?
    analyzer = [
      ENV['OPENSHIFT_BUILD_NAMESPACE'], # hit-jubla-int
      ENV['RAILS_DB_NAME'],             # hit_jubla_development
      "hitobito-#{Rails.env}"           # hitobito-development
    ].compact.first.yield_self do |name|
      ProjectAnalyzer.new(name)
    end

    config.tags[:project]      = analyzer.project
    config.current_environment = analyzer.stage

    config.excluded_exceptions += [
      'ActiveRecord::ConnectionNotEstablished',
      'Errno::ECONNREFUSED',
      'Errno::ECONNRESET',
      'Errno::EFAULT',
      'Errno::ENETUNREACH',
      'Errno::ENOMEM',
      'Mysql2::Error::ConnectionError',
      'Net::OpenTimeout',
      'Net::ReadTimeout',
      'SignalException',
      'ThinkingSphinx::ConnectionError',
      'Timeout::Error',
    ]
  end
end
