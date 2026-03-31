# frozen_string_literal: true

#  Copyright (c) 2026, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

class EventReadables < GroupBasedReadables
  self.same_group_permissions = []
  self.above_group_permissions = []
  self.same_layer_permissions = [:any]
  self.above_layer_permissions = [:layer_and_below_full]

  def initialize(user)
    super
    can :read, Event, accessible_events
  end

  private

  def accessible_events
    return Event.all if user.root?

    Event.joins(:groups).where(accessible_conditions.to_a).distinct
  end

  def accessible_conditions
    OrCondition.new.tap do |condition|
      in_same_layer_condition(condition)
      in_above_layer_condition(condition)
      globally_visible_condition(condition)
      participating_condition(condition)
      public_condition(condition)
    end
  end

  def globally_visible_condition(condition)
    condition.or("#{Event.quoted_table_name}.globally_visible IS TRUE")
  end

  def participating_condition(condition)
    condition.or("#{Event.quoted_table_name}.id IN (?)",
      user_context.participations.pluck(:event_id))
  end

  def public_condition(condition)
    condition.or("#{Event.quoted_table_name}.external_applications IS TRUE")
  end
end
