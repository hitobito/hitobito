# frozen_string_literal: true

# Copyright (c) 2022-2023, Hitobito AG. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito.

# Restrict code-execution depending on settings-level feature-switches
#
# Provides the following class-level methods
#   - assert!(feature)    # raises unless the feature is active
#   - enabled?(feature)   # answers if the feature is active
#   - if(feature) { ... } # executes block if feature is active

# In config/settings.yml any key can have a subkey "enabled" which determines
# if a given feature is enabled. For example:
#
# # settings.yml
# groups:
#   self_registration:
#     enabled: true
#
# # anywhere in the application
# FeatureGate.if('groups.self_registration') do
#   # Code activated if feature is configured active
# end
#
class FeatureGate
  class FeatureGateError < StandardError; end

  def initialize(settings = Settings)
    @settings = settings
  end

  class << self
    # Raise unless the feature is enabled
    def assert!(feature)
      new.assert!(feature)
    end

    # Execute the block if the feature is enabled
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
    return send("#{feature}_enabled?") if respond_to?("#{feature}_enabled?", true)

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

  def person_language_enabled?
    # some rake tasks run without db present, so make sure
    # this doesn't fail in those cases
    ActiveRecord::Base.connection.table_exists?('people') &&
      !Person.has_attribute?(:correspondence_language)
  end

  def self_registration_reason_enabled?
    SelfRegistrationReason.table_exists? && SelfRegistrationReason.exists?
  end
end
