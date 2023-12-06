# frozen_string_literal: true

#  Copyright (c) 2023, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Group::PrivacyPolicyFinder

  def initialize(group, person)
    @group = group
    @person = person
  end

  def self.for(group: nil, person: nil)
    new(group, person)
  end

  def acceptance_needed?
    groups.any? && !already_accepted?
  end

  def groups
    @groups ||= @group.layer_hierarchy(includes: [:privacy_policy_attachment]).select do |g|
      g.privacy_policy.present?
    end
  end

  private

  def already_accepted?
    return false unless @person.is_a?(ActiveRecord::Base)

    @person.privacy_policy_accepted? && @person.changes.keys.exclude?('privacy_policy_accepted_at')
  end
end
