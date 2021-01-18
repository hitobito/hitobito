# frozen_string_literal: true

#  Copyright (c) 2012-2021, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class MessagesController < CrudController

  include YearBasedPaging

  PERMITTED_TEXT_MESSAGE_ATTRS = [:type, :text].freeze
  PERMITTED_LETTER_ATTRS = [:type, :subject, :body].freeze
  PERMITTED_INVOICE_LETTER_ATTRS = [:type, :subject, :body,
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
    raise_type_error unless well_known?(type)
    type.constantize.new(mailing_list: parent, sender: current_user)
  end

  def type
    model_params && model_params[:type].presence
  end

  def well_known?(type)
    type_class = type.safe_constantize
    type_class && type_class <= Message
  end

  def raise_type_error
    raise ActiveRecord::RecordNotFound, "No message type '#{type}' found"
  end

  def permitted_attrs
    case type
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
