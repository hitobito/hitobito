# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class QualificationAbility < AbilityDsl::Base

  on(Qualification) do
    permission(:layer_full).may(:create, :destroy).in_course_layer
    permission(:layer_and_below_full).may(:create, :destroy).in_course_layer_or_below
  end

  def in_course_layer
    in_course_layer_with(:layer_full, subject.person.layer_group_ids)
  end

  def in_course_layer_or_below
    in_course_layer_with(:layer_and_below_full, subject.person.groups_hierarchy_ids)
  end

  private

  def in_course_layer_with(permission, person_layer_ids)
    layers = user.groups_with_permission(permission).collect(&:layer_group).uniq
    qualify_layer_ids = layers.select { |g| g.event_types.include?(Event::Course) }.
                               collect(&:id)

    qualify_layer_ids.present? &&
    contains_any?(qualify_layer_ids, person_layer_ids)
  end

end
