# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# This class is only used for fetching lists based on a group association.
class PersonReadables < PersonFetchables

  self.same_group_permissions = [:group_full, :group_read]
  self.same_layer_permissions = [:layer_and_below_full, :layer_and_below_read,
                                 :layer_full, :layer_read]
  self.above_layer_permissions = [:layer_and_below_full, :layer_and_below_read]

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

    elsif contact_data_visible?
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
    OrCondition.new.tap do |condition|
      condition.or(*herself_condition)
      condition.or(*contact_data_condition) if contact_data_visible?
      append_group_conditions(condition)
    end
  end

  def contact_data_condition
    ['people.contact_data_visible = ?', true]
  end

  def herself_condition
    ['people.id = ?', user.id]
  end

  def read_permission_for_this_group?
    group_read_in_this_group? ||
    layer_read_in_same_layer? ||
    layer_and_below_read_in_same_layer? ||
    user.root?
  end

  def contact_data_visible?
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

end
