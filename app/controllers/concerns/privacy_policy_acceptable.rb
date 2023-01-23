# frozen_string_literal: true

#  Copyright (c) 2023, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module PrivacyPolicyAcceptable
  extend ActiveSupport::Concern

  included do
    prepend_before_action :policy_finder

    if respond_to?(:after_save)
      after_save :set_privacy_policy_acceptance, if: :privacy_policy_needed_and_accepted?
    end
  end

  private

  def privacy_policy_needed_and_accepted?
    policy_finder.acceptance_needed? && privacy_policy_accepted?
  end

  def set_privacy_policy_acceptance
    person.privacy_policy_accepted = true
    person.save
  end

  def privacy_policy_accepted?
    return true unless policy_finder.acceptance_needed?

    true?(privacy_policy_param)
  end

  def add_privacy_policy_not_accepted_error(e = person)
    e.errors.add(:base, t('.flash.privacy_policy_not_accepted')) unless privacy_policy_accepted?
  end

  def policy_finder
    @policy_finder ||= Group::PrivacyPolicyFinder.for(group: group, person: person)
  end

  def privacy_policy_param
    model_params[:privacy_policy_accepted]
  end
end
