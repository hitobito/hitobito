# encoding: utf-8

#  Copyright (c) 2020, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Pdf
  module Messages::Letter

    PLACEHOLDERS = %i[salutation first_name last_name]

    class Runner
      def render(letter)
        pdf = Prawn::Document.new(page_size: 'A4',
                                  page_layout: :portrait,
                                  margin: 2.cm)
        customize(pdf)
        letter.message_recipients.each do |recipient|
          sections.each { |section| section.new(pdf, letter, self).render(recipient) }
          pdf.start_new_page unless recipient == letter.message_recipients.last
        end
        pdf.render
      end

      def salutation(recipient)
        I18n.t('global.salutation')
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

    def self.render(letter, opts={})
      runner.new.render(letter)
    end

    def self.filename(letter, opts={})
      "#{letter.subject.parameterize(separator: '_')}.pdf"
    end
  end
end
