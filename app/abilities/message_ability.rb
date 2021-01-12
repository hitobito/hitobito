# frozen_string_literal: true

#  Copyright (c) 2021, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class MessageAbility < AbilityDsl::Base

  on(Message) do
    permission(:any).may(:edit).if_type_and_writable
  end

  def if_type_and_writable
    not_bulk_mail && if_recipients_source_writable
  end

  private

  def not_bulk_mail
    !subject.is_a?(Messages::BulkMail)
  end

  def if_recipients_source_writable
    Ability.new(user).can?(:update, subject.recipients_source)
  end

end
