# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Pdf
  module Participation

    class Runner
      class_attribute :sections, :font, :font_size, :stroke_bounds

      self.font = 'Helvetica'
      self.font_size = 9
      self.stroke_bounds = false


      def render(participation)
        pdf = Prawn::Document.new(page_size: 'A4',
                                  page_layout: :portrait,
                                  margin: 2.cm)
        pdf.font font
        pdf.font_size font_size

        sections.each { |section| section.new(pdf, participation).render }
        pdf.render
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
  end
end
