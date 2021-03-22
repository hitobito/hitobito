# frozen_string_literal: true

#  Copyright (c) 2012-2021, Die Mitte Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module RenderMessagesExports
  extend ActiveSupport::Concern

  def render_pdf(message, preview:)
    @message = message
    pdf = generate_pdf(preview)
    send_data pdf.render, type: :pdf, disposition: :inline, filename: pdf.filename
  end

  private

  def generate_pdf(preview)
    @message.exporter_class.new(@message, recipients, preview: preview)
  end

  def recipients
    person_ids = params[:person_id].to_s.split(',')
    people.where(id: person_ids).exists? ?
      people.where(id: person_ids) :
      people
  end

  def people
    @people ||= case @message
                when Message::LetterWithInvoice, Message::Letter
                  @message.mailing_list.people(Person.with_address)
                when Message::TextMessage
                  @message.mailing_list.people(Person.with_mobile)
                end
  end
end
