# frozen_string_literal: true

#  Copyright (c) 2020-2024, Die Mitte. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Pdf::Messages
  class Letter
    MARGIN = 2.5.cm
    PREVIEW_LIMIT = 4
    BATCH_SIZE = 500

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
      @job = options.delete(:job)
      @body_font_size = Settings.messages.body_font_size
    end

    def pdf
      @pdf ||= Export::Pdf::Document.new(**render_options).pdf.tap do |pdf|
        pdf.font "LiberationSans"
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

      recipient_count = recipients.count

      recipients.each_with_index do |recipient, position|
        @job&.report_progress!(position, recipient_count)
        render_sections(recipient)
        pdf.start_new_page if (position + 1) < recipient_count
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

    def render_options
      @options.to_h.merge(
        margin: MARGIN,
        compress: true
      )
    end

    def customize
      pdf.font_size 9
    end

    def sections
      @sections ||= [Header, Content].collect do |section|
        section.new(pdf, @letter, @options.slice(:debug, :stamped))
      end
    end

    def recipients
      @recipients ||=
        MessageRecipient.find_in_ordered_batches(recipient_ids, batch_size: BATCH_SIZE)
    end

    # We have to pluck people.last_name because Postgres doesn't allow ordering by a column
    # that isn't selected when doing SELECT DISTINCT.
    def recipient_ids # rubocop:todo Metrics/MethodLength
      recipients = @letter.message_recipients
        .joins(:person)
        .where.not(person_id: nil)
        .order(last_name: :asc)
        .distinct

      if @letter.send_to_households?
        recipients
          .group(:address)
          .pluck("MAX(message_recipients.id)", "MAX(people.last_name) AS last_name")
          .map(&:first)
      else
        recipients
          .pluck("message_recipients.id", "people.last_name")
          .map(&:first)
      end
    end
  end
end
