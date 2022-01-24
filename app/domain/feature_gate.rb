# frozen_string_literal: true

# Copyright (c) 2022, Hitobito AG. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito.

class FeatureGate
  SEPARATOR = '.'

  class FeatureGateError < StandardError; end

  class << self
    def assert!(feature)
      new.assert!(feature)
    end

    def if(feature, &block)
      new.if(feature, &block)
    end

    def enabled?(feature)
      new.enabled?(feature)
    end
  end

  def initialize(settings = Settings)
    @settings = settings
  end

  def assert!(feature)
    return if enabled?(feature)
    raise FeatureGateError, "Feature #{feature} is not enabled"
  end

  def if(feature, &block)
    yield if enabled?(feature)
  end

  def enabled?(feature)
    read_config(feature, @settings)[:enabled]
  end

  private

  def read_config(feature, settings)
    config = feature.split(SEPARATOR).inject(settings) do |acc, property|
      acc.nil? ? nil : acc.send(property)
    end

    if config.nil?
        raise FeatureGateError, "No configuration found for feature #{feature}"
    elsif config.enabled.nil?
        raise FeatureGateError, "No key 'enabled' found for feature #{feature}"
    end

    config
  end
end
