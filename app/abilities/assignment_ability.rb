# frozen_string_literal: true

#  Copyright (c) 2012-2026, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AssignmentAbility < AbilityDsl::Base
  on(Assignment) do
    class_side(:index).all

    permission(:any).may(:show, :edit, :update).if_attachment_readable?
    permission(:any).may(:new, :create).if_attachment_writeable?
    permission(:any).may(:destroy).none
  end

  def if_attachment_readable?
    any_of(*attachment_conditions(:show))
  end

  def if_attachment_writeable?
    any_of(*attachment_conditions(:create), *attachment_conditions(:update))
  end

  private

  def attachment_conditions(action)
    Assignment::ATTACHMENT_TYPES.map do |type|
      {attachment_type: [type.polymorphic_name, type.sti_name].uniq,
       attachment_id: accessible_ids(type, action)}
    end
  end
end
