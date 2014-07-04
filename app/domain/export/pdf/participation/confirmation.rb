# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Pdf::Participation
  class Confirmation < Section

    def render
      first_page_section do
        render_heading
        render_remarks if event.remarks?
        render_contact_address if contact
      end
    end

    private

    def section_size
      super + 10
    end

    def contact
      application && application.contact
    end

    def render_heading
      text t('.read_and_agreed'), style: :bold
      move_down_line
    end

    def render_remarks
      y = cursor

      with_settings(line_width: 0.9, fill_color: 'cccccc') do
        fill_and_stroke_rectangle [0, y], bounds.width, 70
      end

      pdf.bounding_box([0 + 5, y - 5], width: bounds.width, height: 65) do
        shrinking_text_box event.remarks
      end
      move_down_line
    end

    def render_contact_address
      text t('event.applied_to'), style: :bold

      pdf.bounding_box([10, cursor], width: bounds.width) do
        text t('contactable.address_or_email',
               address: [contact.to_s, contact.address, contact.zip_code, contact.town].join(', '),
               email: contact.email)
      end
    end

    def label_with_dots(content)
      text content
      move_down_line
      text '.' * 55
    end
  end
end
