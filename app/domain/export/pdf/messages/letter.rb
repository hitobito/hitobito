# frozen_string_literal: true

#  Copyright (c) 2020-2024, Die Mitte. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Pdf::Messages
  class Letter
    MARGIN = 2.5.cm
    PREVIEW_LIMIT = 4

    class << self
      def export(_format, letter)
        new(letter).render
      end

      def preview(_format, letter)
        new(letter).render_preview
      end
    end

    def initialize(letter, options = {})
      @letter = letter
      @options = options
      @async_download_file = options.delete(:async_download_file)
      @body_font_size = Settings.messages.body_font_size
    end

    def pdf
      @pdf ||= Export::Pdf::Document.new(**render_options).pdf.tap do |pdf|
        pdf.font "Helvetica"
      end
    end

    def render_preview
      ActiveRecord::Base.transaction do
        ::Messages::LetterDispatch.new(@letter, recipient_limit: PREVIEW_LIMIT).run
        build_pdf
        raise ActiveRecord::Rollback
      end
      pdf.render
    end

    def render
      build_pdf
      pdf.render
    end

    def build_pdf
      customize
      recipients.each_with_index do |recipient, position|
        reporter&.report(position)
        render_sections(recipient)
        pdf.start_new_page unless last?(recipient)
      end
    rescue PDF::Core::Errors::EmptyGraphicStateStack
      Rails.logger.warn "Unable to stamp content for letter: #{@letter.id}"
      prepare_retry
      retry
    end

    def prepare_retry
      @options[:stamped] = false
      @sections = nil
      @pdf = nil
    end

    def render_sections(recipient)
      sections.each do |section|
        section.render(recipient, font_size: @body_font_size)
      end
    end

    def filename(*parts)
      parts += [@letter.subject.parameterize(separator: "_")]
      yield parts if block_given?
      [parts.join("-"), :pdf].join(".")
    end

    private

    def reporter
      return unless @async_download_file

      @reporter ||= init_reporter
    end

    def init_reporter
      Export::ProgressReporter.new(
        @async_download_file,
        recipients.size
      )
    end

    def render_options
      @options.to_h.merge(
        margin: MARGIN,
        compress: true
      )
    end

    def customize
      pdf.font_size 9
    end

    def last?(recipient)
      recipients.last == recipient
    end

    def sections
      @sections ||= [Header, Content].collect do |section|
        section.new(pdf, @letter, @options.slice(:debug, :stamped))
      end
    end

    def recipients
      @recipients ||= message_recipients
    end

    def message_recipients
      recipients = @letter.message_recipients.select("message_recipients.*", "people.last_name")
        .where.not(person_id: nil)
        .joins(:person).order(last_name: :asc)
        .distinct

      if @letter.send_to_households?
        recipients = recipients.unscope(:select)
          .select("MAX(people.last_name)", "MAX(message_recipients.id)",
            "MAX(people.last_name) AS last_name",
            "MAX(message_recipients.message_id)",
            "MAX(message_recipients.person_id)",
            "MAX(message_recipients.phone_number)",
            "MAX(message_recipients.email)", "MAX(message_recipients.created_at)",
            "MAX(message_recipients.failed_at)", "MAX(message_recipients.error)",
            "MAX(message_recipients.invoice_id)", "MAX(message_recipients.state)",
            "MAX(message_recipients.salutation)", "MAX(message_recipients.error)",
            :address).group(:address)
      end
      recipients
    end
  end
end
