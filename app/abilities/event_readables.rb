# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

class EventReadables < GroupBasedReadables
  def initialize(user)
    super

    can :index, Event, accessible_events
  end

  private

  def accessible_events
    return Event.all if user.root?
    return Event.none unless user.roles.any?

    Event.joins(:groups).where(accessible_conditions.to_a).distinct
  end

  def accessible_conditions
    OrCondition.new.tap do |condition|
      any_in_same_layer_condition(condition)
      public_condition(condition)
      participating_condition(condition)
      token_accessible_condition(condition)
      in_above_layer_condition(condition)
    end
  end

  def any_in_same_layer_condition(condition)
    condition.or("#{Group.quoted_table_name}.layer_group_id IN (?)",
      user.roles.map { |role| role.group.layer_group_id })
  end

  def public_condition(condition)
    condition.or("globally_visible").or("external_applications")
  end

  def participating_condition(condition)
    condition.or("events.id IN (#{participations.select(:event_id).to_sql})")
  end

  def participations
    Event::Participation
      .active
      .where(participant_id: user.id, participant_type: "Person")
  end

  def token_accessible_condition(condition)
    return condition if user.shared_access_token.blank?

    condition.or("shared_access_token = ?", user.shared_access_token)
  end
end
