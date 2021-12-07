# frozen_string_literal: true

# Copyright (c) 2021, CVP Schweiz. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito.

class Message::TextMessage < Message
  self.icon = :sms

  validates :text, length: { minimum: 1, maximum: 160 }

  def subject
    text && text[0..20]
  end

  def update_message_status!
    failed_count = message_recipients.where(state: 'failed').count
    success_count = message_recipients.where(state: 'sent').count
    state = success_count.eql?(0) && failed_count.positive? ? 'failed' : 'finished'
    update!(success_count: success_count, failed_count: failed_count, state: state)
  end

end
