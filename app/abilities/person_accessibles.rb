# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# This class is only used for fetching lists based on a group association.
class PersonAccessibles < PersonFetchables

  attr_reader :group

  delegate :groups_group_read, :layers_read, :layers_and_below_read, to: :user_context

  def initialize(user, group = nil)
    super(user)
    @group = group

    if @group.nil?
      can :index, Person, accessible_people { |_| true }
    else # optimized queries for a given group
      group_accessible_people
    end
  end

  private

  def group_accessible_people
    if read_permission_for_this_group?
      can :index, Person,
          group.people.only_public_data { |_| true }

    elsif layer_and_below_read_in_above_layer?
      can :index, Person,
          group.people.only_public_data.visible_from_above(group) { |_| true }

    elsif group_contact_data_visible?
      can :index, Person,
          group.people.only_public_data.contact_data_visible { |_| true }
    end
  end

  def accessible_people
    if user.root?
      Person.only_public_data
    else
      Person.only_public_data.
             joins(roles: :group).
             where(roles: { deleted_at: nil }, groups: { deleted_at: nil }).
             where(accessible_conditions.to_a).
             uniq
    end
  end

  def accessible_conditions
    condition = OrCondition.new
    condition.or(*herself_condition)
    condition.or(*contact_data_condition) if user.contact_data_visible?
    append_group_conditions(condition)

    condition
  end

  def append_group_conditions(condition)
    condition.or(*in_same_group_condition) if groups_group_read.present?

    if layers_and_below_read.present? || layers_read.present?
      condition.or(*in_same_layer_condition(read_layer_groups))
    end

    if layers_and_below_read.present?
      condition.or(*visible_from_above_condition(read_layer_and_below_groups))
    end
  end

  def contact_data_condition
    ['people.contact_data_visible = ?', true]
  end

  def herself_condition
    ['people.id = ?', user.id]
  end

  def in_same_group_condition
    ['groups.id IN (?)', groups_group_read]
  end

  def read_permission_for_this_group?
    group_read_in_this_group? ||
    layer_read_in_same_layer? ||
    layer_and_below_read_in_same_layer? ||
    user.root?
  end

  def group_contact_data_visible?
    user.contact_data_visible?
  end

  def group_read_in_this_group?
    groups_group_read.include?(group.id)
  end

  def layer_read_in_same_layer?
    layers_read.present? &&
    layers_read.include?(group.layer_group_id)
  end

  def layer_and_below_read_in_same_layer?
    layers_and_below_read.present? &&
    layers_and_below_read.include?(group.layer_group_id)
  end

  def layer_and_below_read_in_above_layer?
    layers_and_below_read.present? &&
    (layers_and_below_read & group.layer_hierarchy.collect(&:id)).present?
  end

  def read_layer_groups
    (read_layer_and_below_groups +
     user.groups_with_permission(:layer_full) +
     user.groups_with_permission(:layer_read)).
      collect(&:layer_group).uniq
  end

  def read_layer_and_below_groups
    (user.groups_with_permission(:layer_and_below_full) +
     user.groups_with_permission(:layer_and_below_read)).
      collect(&:layer_group).uniq
  end

end
