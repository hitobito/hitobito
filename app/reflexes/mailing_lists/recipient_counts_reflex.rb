# frozen_string_literal: true

#  Copyright (c) 2021, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class MailingLists::RecipientCountsReflex < ApplicationReflex
  include ParamConverters

  delegate :t, to: I18n

  # TODO authorization?
  # skip_authorization_check

  def count
    @send_to_households = true?(element.value)
    info
  end

  def init_count(send_to_households)
    @send_to_households = send_to_households
    info
  end

  private

  def info
    @valid_recipient_info = valid_recipient_info
    @invalid_recipient_info = invalid_recipient_info
  end

  def valid_recipient_info
    t("mailing_lists.recipient_counts.index.recipient_info.#{translation_key}.valid",
      count: recipient_counter.valid,
      model_class: human_message_type)
  end

  def invalid_recipient_info
    return '' if recipient_counter.invalid.zero?

    info = t("mailing_lists.recipient_counts.index.recipient_info.#{translation_key}.invalid",
             count: recipient_counter.invalid,
             model_class: human_message_type)

    "(#{info})"
  end

  def translation_key
    return "#{message_type.underscore}.households" if @send_to_households
    "#{message_type.underscore}.people"
  end

  def mailing_list
    MailingList.find(element.dataset[:id])
  end

  def message_type
    element.dataset[:message_type]
  end

  def human_message_type
    message_type.constantize.model_name.human
  rescue
    message_type
  end

  def recipient_counter
    @recipient_counter ||=
      MailingList::RecipientCounter
      .new(mailing_list, message_type, @send_to_households)
  end

end
