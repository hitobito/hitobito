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
      text t(".read_and_agreed_for_#{i18n_event_postfix}"), style: :bold
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

  end
end
