# frozen_string_literal: true

#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::QuestionTemplateAbility < AbilityDsl::Base
  include AbilityDsl::Constraints::Group

  on(Event::QuestionTemplate) do
    permission(:layer_full).may(:manage).in_same_layer
    permission(:layer_and_below_full).may(:manage).in_same_layer_or_below
  end

  private

  def group
    subject.group
  end
end
