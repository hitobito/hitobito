# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class QualificationAbility < AbilityDsl::Base

  on(Qualification) do
    permission(:layer_full).may(:create, :destroy).in_course_layer_or_below
  end

  def in_course_layer_or_below
    layers_full = user_context.user.groups_with_permission(:layer_full).collect(&:layer_group)
    qualify_layer_ids = layers_full.select {|g| g.event_types.include?(Event::Course) }.collect(&:id)
    qualify_layer_ids.present? &&
    contains_any?(qualify_layer_ids, subject.person.groups_hierarchy_ids)
  end

end