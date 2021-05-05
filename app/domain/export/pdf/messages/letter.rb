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

    def initialize(letter, recipients, options = {})
      @letter = letter
      @recipients = recipients
      @options = options
      @async_download_file = options.delete(:async_download_file)
    end

    def pdf
      @pdf ||= Prawn::Document.new(render_options)
    end

    def render
      customize
      @recipients.each_with_index do |recipient, position|
        reporter&.report(position)
        render_sections(recipient)
        pdf.start_new_page unless last?(recipient)
      end
      pdf.render
    rescue PDF::Core::Errors::EmptyGraphicStateStack
      Rails.logger.warn "Unable to stamp content for letter: #{@letter.id}"
      @options[:stamped] = false
      @sections = nil
      @pdf = nil
      retry
    end

    def render_sections(recipient)
      sections.each do |section|
        section.render(recipient)
      end
    end

    def filename(*parts)
      parts += [@letter.subject.parameterize(separator: '_')]
      yield parts if block_given?
      [parts.join('-'), :pdf].join('.')
    end

    private

    def reporter
      @reporter ||= Export::ProgressReporter.new(
        AsyncDownloadFile::DIRECTORY.join(@async_download_file),
        @recipients.size
      ) if @async_download_file
    end

    def render_options
      @options.to_h.merge(
        page_size: 'A4',
        page_layout: :portrait,
        margin: 2.cm,
        compress: true
      )
    end

    def customize
      pdf.font_size 9
    end

    def last?(recipient)
      @recipients.last == recipient
    end

    def sections
      @sections ||= [Header, Content].collect do |section|
        section.new(pdf, @letter, @options.slice(:debug, :stamped))
      end
    end
  end
end
