# encoding: utf-8

#  Copyright (c) 2012-2015, Pfadibewegung Schweiz. This file is part of
#  hitobito_pbs and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pbs.
#
# Fetches people for which the user has write access via layer permissions.
class PersonWritables < PersonFetchables

  include CanCan::Ability

  attr_reader :user_context

  delegate :user, :layers_full, :layers_and_below_full, to: :user_context

  def initialize(user)
    super(user)

    can :index, Person, accessible_people { |_| true }
  end

  private

  def accessible_people
    if user.root?
      Person.only_public_data
    elsif writable_conditions.present?
      accessible_people_scope
    else
      Person.none
    end
  end

  def accessible_people_scope
    Person.only_public_data.
      joins(roles: :group).
      where(roles: { deleted_at: nil }, groups: { deleted_at: nil }).
      where(writable_conditions.to_a).
      uniq
  end

  def writable_conditions
    condition = OrCondition.new

    if layers_and_below_full.present? || layers_full.present?
      condition.or(*in_same_layer_condition(full_layer_groups))
    end

    if layers_and_below_full.present?
      condition.or(*visible_from_above_condition(full_layer_and_below_groups))
    end

    condition
  end

  def full_layer_groups
    (full_layer_and_below_groups +
     user.groups_with_permission(:layer_full)).
      collect(&:layer_group).uniq
  end

  def full_layer_and_below_groups
    user.groups_with_permission(:layer_and_below_full) .
      collect(&:layer_group).uniq
  end

end
