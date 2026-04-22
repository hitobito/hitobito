# frozen_string_literal: true

#  Copyright (c) 2023, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::InactivityBlockMailer < ApplicationMailer
  CONTENT_INACTIVITY_BLOCK_WARNING = "content_inactivity_block_warning"

  def inactivity_block_warning(recipient)
    @recipient = recipient
    compose(recipient.email, CONTENT_INACTIVITY_BLOCK_WARNING)
  end

  private

  def placeholder_recipient_name
    @recipient.greeting_name
  end

  def placeholder_warn_after_days
    Person::BlockService.warn_after_days&.to_s
  end

  def placeholder_block_after_days
    Person::BlockService.block_after_days&.to_s
  end
end
