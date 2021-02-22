#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Pdf
  module List
    class Runner
      def render(contactables, group)
        pdf = Prawn::Document.new(page_size: "A4",
                                  page_layout: :portrait,
                                  margin: 1.cm)
        pdf.font_size Settings.pdf.font_size
        sections.each { |section| section.new(pdf, contactables, group).render }
        footer(pdf)
        pdf.render
      end

      private

      def sections
        [Header, People]
      end

      def footer(pdf)
        pdf.number_pages(I18n.t("event.participations.print.page_of_pages"),
          at: [0, 0],
          align: :right)

        pdf.repeat(:all) do
          pdf.bounding_box([0, 0], width: pdf.bounds.width, height: 2.cm) do
            pdf.text I18n.l(Time.current)
          end
        end
      end
    end

    mattr_accessor :runner

    self.runner = Runner

    def self.render(contactables, group)
      runner.new.render(contactables, group)
    end
  end
end
