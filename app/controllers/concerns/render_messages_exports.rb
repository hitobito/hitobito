# frozen_string_literal: true

#  Copyright (c) 2012-2021, Die Mitte Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module RenderMessagesExports
  extend ActiveSupport::Concern

  def render_pdf(message, preview:)
    assert_type(message)
    assert_recipients(message)

    pdf = message.exporter_class.new(message, recipients(message), preview: preview)
    send_data pdf.render, type: :pdf, disposition: :inline, filename: pdf.filename
  end

  def render_pdf_in_background(message)
    assert_type(message)
    assert_recipients(message)

    base_name = message.exporter_class.new(message, Person.none, preview: false).filename
    with_async_download_cookie(:pdf, base_name) do |filename|
      Export::MessageJob.new(current_person.id, message.id, filename).enqueue!
    end
  end

  private

  def assert_type(message)
    raise "cannot create pdf for #{message.type}" unless message.is_a?(Message::Letter)
  end

  def assert_recipients(message)
    if recipients(message).count == 0
      raise Messages::NoRecipientsError
    end
  end

  def recipients(message)
    message.mailing_list.people(Person.with_address).limit(5) # no need to query all recipients
  end

end
