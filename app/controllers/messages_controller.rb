# frozen_string_literal: true

#  Copyright (c) 2012-2024, Die Mitte Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class MessagesController < CrudController
  include RenderMessagesExports
  include YearBasedPaging
  include AsyncDownload

  PERMITTED_TEXT_MESSAGE_ATTRS = [:text] # rubocop:disable Style/MutableConstant meant to be extended
  PERMITTED_LETTER_ATTRS = [:subject, :body, :salutation, :send_to_households, # rubocop:disable Style/MutableConstant meant to be extended
                            :pp_post, :shipping_method, :date_location_text]
  PERMITTED_INVOICE_LETTER_ATTRS = [:subject, :body, :salutation, :donation_confirmation, # rubocop:disable Style/MutableConstant meant to be extended
                                    :pp_post, :shipping_method, :date_location_text,
                                    invoice_attributes: [
                                      :issued_at,
                                      invoice_items_attributes: [
                                        :name,
                                        :description,
                                        :cost_center,
                                        :account,
                                        :unit_cost,
                                        :vat_rate,
                                        :count,
                                        :type,
                                        :_destroy
                                      ]
                                    ]]

  self.nesting = [Group, MailingList]
  self.remember_params += [:year]

  before_action :authorize_duplicate, only: :new

  def show
    respond_to do |format|
      format.html
      format.pdf do
        if preview?
          render_pdf_preview
        else
          render_pdf_in_background
        end
      end
    end
  end

  def new
    assign_attributes_from_duplication_source if duplication_source.present?
    super
  end

  private

  def assign_attributes_from_duplication_source
    # We can't simply assign .attributes because the rich text body is not included in .attributes
    duplication_source.class.duplicatable_attrs.each do |attr|
      entry.send("#{attr}=", duplication_source.send(attr))
    end
  end

  def assign_attributes
    super

    return unless entry.invoice?

    if params[:invoice_items].present?
      entry.invoice.invoice_items = params[:invoice_items].map do |type|
        item = InvoiceItem.type_mappings[type.to_sym].new
        item.name = item.model_name.human
        item
      end
    end
  end

  def list_entries
    super
      .list
      .includes(:group, :mail_log)
      .page(params[:page]).per(50).where(created_at: year_filter)
  end

  def build_entry
    type = model_params && model_params[:type]
    message = Message.find_message_type!(type).new
    message.mailing_list = parent
    message.sender = current_user
    message
  end

  def preview?
    true?(params[:preview])
  end

  def permitted_params
    p = model_params.dup
    p.delete(:type)
    p = p.permit(permitted_attrs)

    return p unless entry.invoice? && p.dig(:invoice_attributes, :invoice_items_attributes)

    p.tap do |permitted|
      permitted.dig(:invoice_attributes, :invoice_items_attributes).each do |index, attrs|
        parameters = params.dig(:message, :invoice_attributes, :invoice_items_attributes,
                                index, :dynamic_cost_parameters)
        attrs[:dynamic_cost_parameters] = parameters&.to_unsafe_hash || {}
      end
    end
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

  def duplication_source
    @duplication_source ||= Message.find_by(id: params[:duplicate_from])
  end

  def authorize_class
    authorize!(:update, parent)
  end

  def authorize_duplicate
    authorize!(:show, duplication_source) if duplication_source.present?
  end
end
