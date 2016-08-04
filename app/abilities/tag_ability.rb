# encoding: utf-8

#  Copyright (c) 2012-2016, Dachverband Schweizer Jugendparlamente. This file is part of
#  hitobito_dsj and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_dsj.

class TagAbility < AbilityDsl::Base

  include AbilityDsl::Constraints::Person

  on(Tag) do
    permission(:layer_full).
      may(:create, :show, :destroy).
      on_person_in_same_layer

    permission(:layer_and_below_full).
      may(:create, :show, :destroy).
      on_person_in_same_layer_or_below
  end

  def on_person_in_same_layer
    person_tag? && in_same_layer
  end

  def on_person_in_same_layer_or_below
    person_tag? && in_same_layer_or_below
  end

  private

  def person
    person_tag? && subject.taggable
  end

  def person_tag?
    subject.taggable_type == 'Person'
  end

end
