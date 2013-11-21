# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class PersonAbility < AbilityDsl::Base

  on(Person) do
    permission(:any).may(:index, :query).all
    permission(:any).may(:show, :show_full, :history, :update, :update_email, :primary_group).herself

    permission(:admin).may(:update_email).all

    permission(:contact_data).may(:show).other_with_contact_data

    permission(:group_read).may(:show, :show_details).in_same_group

    permission(:group_full).may(:show_full, :history).in_same_group
    permission(:group_full).may(:update, :primary_group, :send_password_instructions).non_restricted_in_same_group
    permission(:group_full).may(:update_email).for_person_without_password
    permission(:group_full).may(:create).all  # restrictions are on Roles

    permission(:layer_read).may(:show, :show_full, :show_details, :history).in_same_layer_or_visible_below

    permission(:layer_full).may(:update, :primary_group, :send_password_instructions).non_restricted_in_same_layer_or_visible_below
    permission(:layer_full).may(:update_email).for_person_without_password
    permission(:layer_full).may(:create).all # restrictions are on Roles

    general(:send_password_instructions).not_self
  end

  def herself
    subject.id == user.id
  end

  def not_self
    subject.id != user.id
  end

  def other_with_contact_data
    subject.contact_data_visible?
  end

  def for_person_without_password
    !subject.password?
  end

  def in_same_group
    permission_in_groups?(subject.group_ids)
  end

  def in_same_layer_or_visible_below
    permission_in_layers?(subject.layer_group_ids) ||
    permission_in_layers?(subject.above_groups_visible_from.collect(&:id))
  end

  def non_restricted_in_same_group
    permission_in_groups?(subject.non_restricted_groups.collect(&:id))
  end

  def non_restricted_in_same_layer_or_visible_below
    permission_in_layers?(subject.non_restricted_groups.collect(&:layer_group_id)) ||
    permission_in_layers?(subject.above_groups_visible_from.collect(&:id))
  end
end