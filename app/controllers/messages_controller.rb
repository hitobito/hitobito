# frozen_string_literal: true

#  Copyright (c) 2012-2021, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class MessagesController < CrudController

  include YearBasedPaging

  PERMITTED_TEXT_MESSAGE_ATTRS = [:text].freeze
  PERMITTED_LETTER_ATTRS = [:subject, :body].freeze
  PERMITTED_INVOICE_LETTER_ATTRS = [:subject, :body,
                                    invoice_attributes: {
                                      invoice_items_attributes: [
                                        :name,
                                        :description,
                                        :unit_cost,
                                        :vat_rate,
                                        :count,
                                        :cost_center,
                                        :account,
                                        :_destroy
                                      ]
                                    }].freeze

  self.nesting = [Group, MailingList]
  self.remember_params += [:year]

  before_render_form :set_recipient_count

  private

  def list_entries
    super.list.page(params[:page]).per(50).where(created_at: year_filter)
  end

  def build_entry
    type = model_params && model_params[:type]
    message = Message.find_message_type!(type).new
    message.mailing_list = parent
    message.sender = current_user
    message
  end

  def permitted_params
    p = model_params.dup
    p.delete(:type)
    p.permit(permitted_attrs)
  end

  def permitted_attrs
    case entry.class.sti_name
    when Message::Letter.sti_name
      PERMITTED_LETTER_ATTRS
    when Message::LetterWithInvoice.sti_name
      PERMITTED_INVOICE_LETTER_ATTRS
    when Message::TextMessage.sti_name
      PERMITTED_TEXT_MESSAGE_ATTRS
    end
  end

  def authorize_class
    authorize!(:update, parent)
  end

  def set_recipient_count
    @recipient_count = parent.people.size
  end

end
