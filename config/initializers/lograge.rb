#  Copyright (c) 2019, Schweizer Blasmusikverband. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
#
# Lograge configuration
# Lograge is enabled in the respective environment configs

module LogrageHelper
  def self.stringify_structure(object)
    object
      .inspect
      .tr('"', "'")
      .gsub(/'([^']+)'=>/, '\1: ')
  end

  def self.add_exception(options, ex)
    if ex
      options[:error] = "#{ex.class.to_s}: #{ex.message}"
      options[:backtrace] = Rails.backtrace_cleaner.clean(ex.backtrace)
    end
  end
end


config = Rails.application.config

config.lograge.formatter = Lograge::Formatters::Json.new
config.lograge.base_controller_class = 'ApplicationController'

# Payload is generated after the request for a given controller
config.lograge.custom_payload do |controller|
  {
    request_uuid: controller.request.uuid,
    user_id: controller.send(:current_user).try(:id)
  }.tap do |payload|
    # Log exceptions that are 'swallowed' by the controller (e.g. for 400 bad request)
    # but should still appear in the logs.
    if controller.respond_to?(:rescued_exception) && controller.rescued_exception
      LogrageHelper.add_exception(payload, controller.rescued_exception)
    end
  end
end

# Custom options are added when writing the logs and may access the custom_payload
config.lograge.custom_options = lambda do |event|
  {
    time: Time.zone.now,
    request_uuid: event.payload[:request_uuid],
    params: LogrageHelper.stringify_structure(
      event.payload[:params].except(*%w(controller action format id))
    )
  }.tap do |options|
    LogrageHelper.add_exception(options, event.payload[:exception_object])
  end
end

# Custom options for active job are added when writing the logs
config.lograge_activejob.custom_options = lambda do |event|
  job = event.payload[:job]
  {
    time: Time.zone.now,
    executions: job.executions,
    locale: job.locale,
    args: LogrageHelper.stringify_structure(ActiveJob::Arguments.serialize(job.arguments))
  }.tap do |options|
    LogrageHelper.add_exception(options, event.payload[:exception_object])
  end
end

config.lograge_sql.extract_event = lambda do |event|
  # to include actual query: `sql: event.payload[:sql]`
  { name: event.payload[:name], duration: event.duration.to_f.round(2) }
end

config.lograge_sql.formatter = lambda do |sql_queries|
  sql_queries
end

config.after_initialize do
  # remove other loggers
  if Rails.application.config.lograge.enabled
    require 'lograge/sql/extension'
    ActiveJob::Base.logger = Delayed::Worker.logger = Lograge::SilentLogger.new(Rails.logger)

    # flush stdout after each log statement for immediate downstream processing
    if ENV['RAILS_LOG_TO_STDOUT'].present?
      logger = Rails.logger
      def logger.add(*args, &block)
        super(*args, &block).tap { $stdout.flush }
      end
    end
  end
end
