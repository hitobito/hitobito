# frozen_string_literal: true

#  Copyright (c) 2020, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

class MessagesController < ModalCrudController

  skip_authorize_resource
  skip_before_action :verify_authenticity_token, only: :preview
  before_action :authorize_action

  include YearBasedPaging

  self.nesting = Group, MailingList

  self.permitted_attrs = [:type, :subject, :content, :body]

  helper_method :recipients

  def show
    respond_to do |format|
      format.pdf { render_letter_pdf(entry) }
    end
  end

  def preview
    model_ivar_set(build_entry)
    assign_attributes
    entry.set_message_recipients

    respond_to do |format|
      format.pdf { render_letter_pdf(entry, preview: true) }
    end
  end

  private

  def build_entry
    klazz = model_params ? model_params[:type].constantize : Message.user_types[params[:type]]
    if klazz && Message.user_types.values.include?(klazz)
      klazz.new
    else
      raise "invalid message type provided"
    end
  end

  def find_entry(id=params[:id])
    model_scope.includes(:message_recipients).find(id)
  end

  def full_entry_label
    "#{entry.class.model_name.human} <i>#{ERB::Util.h(entry.to_s)}</i>".html_safe
  end

  def list_entries
    super.in_year(year)
  end

  def parent
    recipients_source
  end

  def recipients_source
    MailingList.find(mailing_list_id)
  end

  def mailing_list_id
    params[:mailing_list_id]
  end

  def assign_attributes
    entry.recipients_source_id = recipients_source.id
    entry.recipients_source_type = recipients_source.class.name
    super
  end

  def authorize_class
    authorize_action
  end

  def authorize_action
    authorize!(:update, recipients_source)
  end

  def return_path
    group_mailing_list_messages_path
  end

  def recipients
    @recipients ||= entry.new_record? ?
                        parent.people.map(&:decorate) :
                        entry.message_recipients.includes(:person).map(&:person).map(&:decorate)
  end

  def render_letter_pdf(letter, opts={})
    pdf = Export::Pdf::Messages::Letter.render(letter, opts)
    filename = Export::Pdf::Messages::Letter.filename(letter, opts)
    send_data pdf, type: :pdf, disposition: 'inline', filename: filename
  end

end
