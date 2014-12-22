# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class GroupAbility < AbilityDsl::Base

  include AbilityDsl::Constraints::Group

  on(Group) do
    permission(:any).may(:read, :index_events, :index_mailing_lists).all
    permission(:any).may(:deleted_subgroups).if_member

    permission(:contact_data).may(:index_people).all

    permission(:group_read).may(:show_details).in_same_group
    # local people are the ones not visible from above
    permission(:group_read).may(:index_people, :index_local_people).in_same_group

    permission(:group_full).
      may(:index_full_people, :update, :reactivate, :export_events).
      in_same_group

    permission(:layer_read).
      may(:show_details, :index_people, :index_local_people, :index_full_people,
          :index_deep_full_people, :export_events).
      in_same_layer

    permission(:layer_full).may(:create).with_parent_in_same_layer
    permission(:layer_full).may(:destroy).in_same_layer_except_permission_giving
    permission(:layer_full).may(:update, :reactivate).in_same_layer

    permission(:layer_and_below_read).
      may(:show_details, :index_people, :index_full_people, :index_deep_full_people,
          :export_subgroups, :export_events).
      in_same_layer_or_below
    permission(:layer_and_below_read).may(:index_local_people).in_same_layer

    permission(:layer_and_below_full).may(:create).with_parent_in_same_layer_or_below
    permission(:layer_and_below_full).may(:destroy).in_same_layer_or_below_except_permission_giving
    permission(:layer_and_below_full).may(:update, :reactivate).in_same_layer_or_below
    permission(:layer_and_below_full).may(:modify_superior).in_below_layers


    general(:update).group_not_deleted
  end

  def with_parent_in_same_layer
    parent = group.parent
    !group.layer? && parent && !parent.deleted? && permission_in_layer?(parent.layer_group_id)
  end

  def with_parent_in_same_layer_or_below
    parent = group.parent
    parent && !parent.deleted? && permission_in_layers?(parent.layer_hierarchy.collect(&:id))
  end

  def in_same_layer_except_permission_giving
    in_same_layer && except_permission_giving
  end

  def in_same_layer_or_below_except_permission_giving
    in_same_layer_or_below && except_permission_giving
  end

  def except_permission_giving
    !(user_context.groups_layer_and_below_full.include?(group.id) ||
      user_context.layers_and_below_full.include?(group.id) ||
      user_context.groups_layer_full.include?(group.id) ||
      user_context.layers_full.include?(group.id))
  end

  def in_below_layers
    permission_in_layers?(group.upper_layer_hierarchy.collect(&:id))
  end

  # mMmber is a general role kind. Return true if user has any member role anywhere.
  def if_member
    user.roles.any? { |r| r.class.member? }
  end

  private

  def group
    subject
  end

end
