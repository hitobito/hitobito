# frozen_string_literal: true

# Copyright (c) 2022, Hitobito AG. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito.

class FeatureGate
  class FeatureGateError < StandardError; end

  def initialize(settings = Settings)
    @settings = settings
  end

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

  def assert!(feature)
    return true if enabled?(feature)

    raise FeatureGateError, "Feature #{feature} is not enabled"
  end

  def if(feature)
    yield if enabled?(feature)
  end

  def enabled?(feature)
    read_config(feature, @settings)[:enabled]
  end

  private

  def read_config(feature, settings)
    config = feature.split('.').reduce(settings) do |acc, property|
      acc.try(property)
    end

    raise FeatureGateError, "No configuration found for feature #{feature}" if config.nil?
    raise FeatureGateError, "No key 'enabled' found for feature #{feature}" if config.enabled.nil?

    config
  end
end
