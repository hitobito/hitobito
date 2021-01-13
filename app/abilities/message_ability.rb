#  frozen_string_literal: true

#  Copyright (c) 2012-2021, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

class MessageAbility < AbilityDsl::Base

  on(Message) do
    permission(:layer_and_below_full)
      .may(:create, :show, :edit, :update, :destroy)
      .in_layer_or_below
  end

  def in_layer_or_below
    permission_in_layers?(subject.group.layer_hierarchy.collect(&:id))
  end

end
