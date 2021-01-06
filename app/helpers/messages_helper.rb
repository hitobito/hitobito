# encoding: utf-8

#  Copyright (c) 2012-2014, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module MessagesHelper

  def message_icon(message)
    return :sms if message.is_a? Messages::TextMessage
    return :'envelope-open-text' if message.is_a? Messages::Letter
    :envelope
  end

  def format_message_type(message)
    icon(message_icon(message), title: message.model_name.human)
  end

  def letter_placeholders
    Export::Pdf::Messages::Letter::PLACEHOLDERS.map { |p| "{#{p.to_s}}" }.join(', ')
  end

  def format_message_state(message)
    return format_bulk_mail_state(message) if message.is_a?(Messages::BulkMail)

    state_counts = message.message_recipients.group(:state).count
    type_mapping = { delivered: 'success', failed: 'important' }
    badges = []
    MessageRecipient::STATES.each do |state|
      count = state_counts[state]
      type = type_mapping.fetch(state.to_sym, 'info')
      badges << badge(message_state_label(state, count), type) if count.present? && count > 0
    end
    safe_join badges, ' '
  end

  def message_state_label(state, count)
    translate(".states.#{state}", count: count)
  end

  def format_bulk_mail_state(message)
    format_mail_log_status(message.mail_log)
  end

end
