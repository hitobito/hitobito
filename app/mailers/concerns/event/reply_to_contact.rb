# frozen_string_literal: true

#  Copyright (c) 2014-2026, CEVI Regionalverband ZH-SH-GL. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Event::ReplyToContact
  extend ActiveSupport::Concern

  included do
    after_action :set_reply_to_from_event_contact
  end

  private

  def set_reply_to_from_event_contact
    return unless Settings.event.use_contact_as_reply_to && event&.contact&.email.present?

    message.reply_to = event.contact.email
  end
end
