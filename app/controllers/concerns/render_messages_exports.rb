# frozen_string_literal: true

#  Copyright (c) 2012-2021, Die Mitte Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module RenderMessagesExports
  extend ActiveSupport::Concern

  def render_pdf_preview(letter = entry)
    assert_type(letter)
    assert_recipients(letter)

    options = { background: Settings.messages.pdf.preview }
    pdf = letter.exporter_class.new(letter, options)
    send_data pdf.render_preview, type: :pdf, disposition: :inline, filename: pdf.filename(:preview)
  end

  def render_pdf_in_background(letter = entry)
    assert_type(letter)
    assert_recipients(letter)

    base_name = letter.exporter_class.new(letter, Person.none).filename
    render_in_background(letter, :pdf, base_name)
  end

  def render_in_background(letter, format, name)
    with_async_download_cookie(format, name) do |filename|
      Export::MessageJob.new(format, current_person.id, letter.id, { filename: filename }).enqueue!
    end
  end

  private

  def assert_type(message)
    raise "cannot create pdf for #{message.type}" unless message.is_a?(Message::Letter)
  end

  def assert_recipients(message)
    unless message.recipients.exists?
      redirect_to message.path_args, alert: t('.recipients_empty')
    end
  end
end
