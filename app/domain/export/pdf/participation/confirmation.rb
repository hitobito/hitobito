# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Pdf::Participation
  class Confirmation < Section

    def render
      first_page_section do
        render_read_and_agreed
        render_signature if event.signature?
        render_signature_confirmation if signature_confirmation?
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

    def render_read_and_agreed
      text I18n.t("event.participations.print.read_and_agreed_for_#{i18n_event_postfix}"), style: :bold
      move_down_line
    end

    def render_contact_address
      text I18n.t('event.applied_to'), style: :bold

      pdf.bounding_box([10, cursor], width: bounds.width) do
        text I18n.t('contactable.address_or_email',
                    address: [contact.to_s, contact.address, contact.zip_code, contact.town].join(', '),
                    email: contact.email)
      end
      move_down_line
    end

    def render_signature_confirmation
      render_signature(event.signature_confirmation_text,
                       'event.participations.print.signature_confirmation')
    end

    def render_signature(header = Event::Role::Participant.model_name.human,
                         key = 'event.participations.print.signature')
      y = cursor
      render_boxed(-> { text header; label_with_dots(location_and_date) },
                   -> { move_down_line; label_with_dots(I18n.t(key)) })
      move_down_line
    end

    def signature_confirmation?
      event.signature_confirmation? && event.signature_confirmation_text?
    end

    def location_and_date
      [Event::Date.human_attribute_name(:location),
       Event::Date.model_name.human].join(' / ')
    end

    def label_with_dots(content)
      text content
      move_down_line
      text '.' * 55
    end

  end
end
