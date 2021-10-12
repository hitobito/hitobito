# encoding: utf-8

#  Copyright (c) 2021, Die Mitte Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class MailingLists::RecipientCountsController < ListController
  skip_authorization_check
  before_action :authorize_action

  helper_method :mailing_list, :group, :valid_recipient_info, :invalid_recipient_info

  def index
    respond_to :js
  end

  self.nesting = [ Group, MailingList ]

  def self.model_class
    MailingList
  end

  private

  alias mailing_list parent

  def group
    mailing_list&.group
  end

  def households
    !!params[:households].presence
  end

  def message_type
    params[:message_type]
  end

  def human_message_type
    message_type.constantize.model_name.human
  rescue
    message_type
  end

  def valid_recipient_info
    t(".recipient_info.valid.#{message_type.underscore}",
      count: recipient_counter.valid,
      model_class: human_message_type)
  end

  def invalid_recipient_info
    return '' if recipient_counter.invalid.zero?

    info = t(".recipient_info.invalid.#{message_type.underscore}",
             count: recipient_counter.invalid,
             model_class: human_message_type)

    "(#{info})"
  end

  def recipient_counter
    @recipient_counter ||= MailingList::RecipientCounter.new(mailing_list, message_type, households)
  end

  def authorize_action
    authorize!(:update, mailing_list)
  end

end
