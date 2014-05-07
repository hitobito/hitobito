# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class BaseJob

  # Define the instance variables defining this job instance.
  # Only these variables will be serizalized when a job is enqueued.
  # Used as airbrake information when the job fails.
  class_attribute :parameters

  def initialize
    store_locale
  end

  def perform
    # override in subclass
  end

  def enqueue!(options = {})
    Delayed::Job.enqueue(self, options)
  end

  def error(_job, exception, payload = parameters)
    logger.error(exception.message)
    logger.error(exception.backtrace.join("\n"))
    Airbrake.notify(exception, cgi_data: ENV.to_hash, parameters: payload)
  end

  def delayed_jobs
    Delayed::Job.where(handler: to_yaml)
  end

  def logger
    Delayed::Worker.logger || Rails.logger
  end

  def store_locale
    @locale = I18n.locale.to_s
  end

  def set_locale
    I18n.locale = @locale || I18n.default_locale
  end

  def parameters
    Array(self.class.parameters).each_with_object({}) do |p, hash|
      hash[p] = instance_variable_get(:"@#{p}")
    end
  end

  # Only create yaml with the defined parameters.
  def encode_with(coder)
    parameters.each do |key, value|
      coder[key.to_s] = value
    end
  end

end
