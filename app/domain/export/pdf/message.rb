# encoding: utf-8

#  Copyright (c) 2020, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Pdf
  module Message

    PLACEHOLDERS = %i[salutation first_name last_name]

    class Runner
      def render(message)
        raise 'Cannot render PDF for this message type' unless message.is_a? Messages::Letter
        pdf = Prawn::Document.new(page_size: 'A4',
                                  page_layout: :portrait,
                                  margin: 2.cm)
        customize(pdf)
        message.message_recipients.each do |recipient|
          sections.each { |section| section.new(pdf, message, self).render(recipient) }
          pdf.start_new_page unless recipient == message.message_recipients.last
        end
        pdf.render
      end

      def salutation(recipient)
        'Hallo!'
      end

      def first_name(recipient)
        recipient.person.first_name
      end

      def last_name(recipient)
        recipient.person.last_name
      end

      private

      def customize(pdf)
        pdf.font_size 9
        pdf
      end

      def sections
        [Header, Content]
      end
    end

    mattr_accessor :runner

    self.runner = Runner

    def self.render(message)
      runner.new.render(message)
    end

    def self.filename(message)
      "#{message.subject.parameterize(separator: '_')}.pdf"
    end
  end
end
