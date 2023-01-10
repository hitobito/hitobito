# frozen_string_literal: true

#  Copyright (c) 2023, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Group::PrivacyPolicyFinder

  def initialize(group)
    @group = group
  end

  def self.for(group: nil)
    new(group)
  end

  def any?
    @group.layer_hierarchy.any? do |g|
      g.privacy_policy.present?
    end
  end

  def privacy_policies
    @group.layer_hierarchy.map do |g|
      g.privacy_policy
    end
  end

end
