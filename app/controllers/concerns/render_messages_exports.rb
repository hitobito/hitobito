# frozen_string_literal: true

#  Copyright (c) 2012-2021, Die Mitte Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module RenderMessagesExports
  extend ActiveSupport::Concern

  def render_pdf(message, preview:)
    raise "cannot create pdf for #{message.type}" unless message.is_a?(Message::Letter)

    @preview = preview
    @message = message
    pdf = generate_pdf(preview)
    send_data pdf.render, type: :pdf, disposition: :inline, filename: pdf.filename
  end

  private

  def generate_pdf(preview)
    @message.exporter_class.new(@message, recipients, preview: preview)
  end

  def recipients
    @recipients ||= fetch_recipients
  end

  def fetch_recipients
    recipients = @message.mailing_list.people(Person.with_address)
    @preview ? recipients.limit(1) : recipients
  end
end
