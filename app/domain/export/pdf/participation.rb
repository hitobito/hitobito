# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Pdf
  module Participation

    class Runner
      def render(participation)
        pdf = Prawn::Document.new(page_size: 'A4',
                                  page_layout: :portrait,
                                  margin: 2.cm)
        customize(pdf)
        sections.each { |section| section.new(pdf, participation).render }
        pdf.number_pages I18n.t('event.participations.print.page_of_pages'), at: [0, 0], align: :right, size: 9
        pdf.render
      end

      private

      def customize(pdf)
        pdf.font_size 9
        pdf

      end

      def sections
        [Header, PersonAndEvent, Specifics, Confirmation, EventDetails]
      end
    end

    mattr_accessor :runner

    self.runner = Runner

    def self.render(participation)
      runner.new.render(participation)
    end

    def self.filename(participation)
      "#{[participation.event.name, participation.person.full_name].join('_')}.pdf"
    end
  end
end
