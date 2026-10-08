# frozen_string_literal: true

#  Copyright (c) 2012-2026, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class QualificationAbility < AbilityDsl::Base
  on(Qualification) do
    permission(:layer_full).may(:create, :destroy).in_course_layer
    permission(:layer_and_below_full).may(:create, :destroy).in_course_layer_or_below

    permission(:any).may(:index).of_fully_readable_people
  end

  def in_course_layer
    layer_ids = qualify_layer_ids(:layer_full)
    {person: {roles: {group: {layer_group_id: layer_ids}}}} if layer_ids.present?
  end

  def in_course_layer_or_below
    layer_ids = qualify_layer_ids(:layer_and_below_full)
    {person: {roles: {group: {lft: below_layers(layer_ids)}}}} if layer_ids.present?
  end

  def of_fully_readable_people
    {person_id: accessible_ids(Person, :show_full)}
  end

  private

  def qualify_layer_ids(permission)
    layers = user.groups_with_permission(permission).collect(&:layer_group).uniq
    layers.select { |g| g.event_types.include?(Event::Course) }.collect(&:id)
  end
end
