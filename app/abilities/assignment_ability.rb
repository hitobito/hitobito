#  frozen_string_literal: true

#  Copyright (c) 2012-2021, CVP Schweiz. This file is part of
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
    attachment_can?(:show)
  end

  def if_attachment_writeable?
    attachment_can?(:create) || attachment_can?(:update)
  end

  def attachment
    subject.attachment
  end

  private

  def attachment_can?(action)
    Ability.new(user).can?(action, attachment)
  end
end
