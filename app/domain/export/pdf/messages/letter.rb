# frozen_string_literal: true

#  Copyright (c) 2020, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Pdf::Messages
  class Letter

    class << self
      def export(_format, letter)
        new(letter).render
      end
    end

    def initialize(letter, options = {})
      @letter = letter
      @options = options
    end

    def render
      pdf = customize(Prawn::Document.new(render_options))
      recipients.each do |recipient|
        render_sections(pdf, recipient)
        pdf.start_new_page unless last?(recipient)
      end
      pdf.render
    end

    def render_sections(pdf, recipient)
      sections.each do |section|
        section.new(pdf, @letter, self).render(recipient)
      end
    end

    def filename
      parts = [@letter.subject.parameterize(separator: '_')]
      parts << %w(preview) if preview?
      yield parts if block_given?
      [parts.join('-'), :pdf].join('.')
    end

    private

    def recipients
      @recipients ||= begin
        recipients = @letter.mailing_list.people(Person.with_address)
        preview? ? recipients.limit(1) : recipients
      end
    end

    def render_options
      preview_option.to_h.merge(
        page_size: 'A4',
        page_layout: :portrait,
        margin: 2.cm
      )
    end

    def preview_option
      { background: Settings.messages.pdf.preview } if preview?
    end

    def customize(pdf)
      pdf.font_size 9
      pdf
    end

    def last?(recipient)
      recipients.last == recipient
    end

    def sections
      [Header, Content]
    end

    def preview?
      @options[:preview]
    end
  end

end
