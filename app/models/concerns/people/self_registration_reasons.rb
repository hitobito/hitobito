# frozen_string_literal: true

#  Copyright (c) 2021, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module People::SelfRegistrationReasons
  extend ActiveSupport::Concern

  included do
    attr_readonly :self_registration_reason,
      :self_registration_reason_id,
      :self_registration_reason_custom_text

    belongs_to :self_registration_reason, optional: true

    validate :assert_self_registration_reason_either_preset_or_custom, 
      if: :self_registration_reason_enabled?
  end

  def self_registration_reason_text
    return unless self_registration_reason_enabled?

    self_registration_reason_custom_text.presence || self_registration_reason&.text
  end

  private

  def assert_self_registration_reason_either_preset_or_custom
    if self_registration_reason_id && self_registration_reason_custom_text.present?
      errors.add(:self_registration_reason_custom_text, :either_preset_or_custom)
    end
  end

  def self_registration_reason_enabled?
    FeatureGate.enabled?(:self_registration_reason)
  end
end
