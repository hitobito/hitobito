# encoding: utf-8

#  Copyright (c) 2012-2016, Dachverband Schweizer Jugendparlamente. This file is part of
#  hitobito_dsj and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_dsj.

class Person::NoteAbility < AbilityDsl::Base

  include AbilityDsl::Constraints::Person

  on(Person::Note) do
    permission(:layer_full).
      may(:create, :show).
      in_same_layer

    permission(:layer_and_below_full).
      may(:create, :show).
      in_same_layer_or_below
  end

  private

  def person
    subject.person
  end

end
