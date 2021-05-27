# frozen_string_literal: true

#  Copyright (c) 2021, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module MessagesHelper

  def add_message_button(type, path = path_args(model_class))
    label = [type.model_name.human, ti(:"link.add").downcase].join(' ')
    action_button(label,
                  new_polymorphic_path(path, message: { type: type }),
                  'plus')
  end

  def available_message_placeholders(editor_id)
    safe_join([t('messages.form.available_placeholders'),
               ' ',
               safe_join(placeholder_links(editor_id), ', ')])
  end

  def format_message_type(message)
    icon(message.class.icon, title: message.type.constantize.model_name.human)
  end

  def format_message_recipients_total(message)
    message.recipients_total.to_s
  end

  def format_message_state(message)
    type = case message.state
           when /pending|draft/ then 'info'
           when /processing/ then 'warning'
           when /finished/ then 'success'
           when /failed/ then 'important'
           end
    badge(message.state_label, type)
  end

  def format_message_infos(message)
    infos = []
    if message.respond_to?(:mail_from) && message.mail_from
      infos << t('messages.table.infos.sender', mail: message.mail_from)
    end
    if message.failed? && message.mail_log.present?
      mail_log_error_key = message.mail_log.status.to_s
      infos <<  t("messages.table.infos.#{mail_log_error_key}")
    end
    infos.join(', ')
  end

  def max_text_message_length
    Message::TextMessage.validators_on(:text).first.options[:maximum]
  end

  def message_recipient_info(message)
    content = link_to([parent.group, parent, :subscriptions, format: :pdf], target: :_blank) do
      message_valid_recipient_info(message)
    end
    content += message_invalid_recipient_info(message)
    content
  end

  def with_recipient_tooltip(message)
    content_tag(:div,
                class: 'btn-group',
                rel: :tooltip,
                'data-placement': :bottom,
                'data-html': true,
                title: message_valid_recipient_info(message)) do
      yield
    end
  end

  def no_letter_recipients(message)
    message.mailing_list.people(Person.with_address).count == 0
  end

  def message_valid_recipient_info(message)
    t(".recipient_info.valid.#{message.type.underscore}",
      count: message.valid_recipient_count,
      model_class: message.model_name.human)
  end

  def format_message_salutation(message)
    Salutation.all[message.salutation] || I18n.t('global.associations.no_entry')
  end

  private

  def message_invalid_recipient_info(message)
    return '' if message.invalid_recipient_count.zero?

    info = t(".recipient_info.invalid.#{message.type.underscore}",
      count: message.invalid_recipient_count,
      model_class: message.model_name.human)

    " (#{info})"
  end

  def placeholder_links(editor_id)
    placeholders = Export::Pdf::Messages::Letter::Content.placeholders
    placeholders.map do |p|
      content_tag(:a,
                  "{#{p}}",
                  { data: { 'clickable-placeholder': editor_id } },
                  false).html_safe
    end
  end
end
