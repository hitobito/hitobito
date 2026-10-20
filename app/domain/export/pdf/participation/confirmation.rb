# frozen_string_literal: true

#  Copyright (c) 2012-2026, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Pdf::Participation
  class Confirmation < Section
    def render
      render_read_and_agreed if event.signature? || signature_confirmation?
      render_signature if event.signature?
      render_signature_confirmation if signature_confirmation?
      render_contact_address if contact_text.present?
    end

    private

    def section_size
      super + 10
    end

    def contact
      application&.contact
    end

    def render_read_and_agreed
      text(I18n.t("event.participations.print.read_and_agreed_for_#{i18n_event_postfix}"),
        style: :bold)
      move_down_line
    end

    def render_contact_address
      text(I18n.t("event.applied_to"), style: :bold)

      pdf.bounding_box([10, cursor], width: bounds.width) do
        text(contact_text)
      end
      move_down_line
    end

    def contact_text
      return if contact.nil?

      address = contact_address.presence
      email = contact_email.presence
      if address && email
        I18n.t("contactable.address_or_email", address: address, email: email)
      else
        address || email
      end
    end

    def render_signature_confirmation
      render_signature(event.signature_confirmation_text,
        "event.participations.print.signature_confirmation")
    end

    def render_signature(header = Event::Role::Participant.model_name.human,
      key = "event.participations.print.signature")
      render_columns(
        lambda do
          text header
          label_with_dots(location_and_date)
        end,
        lambda do
          move_down_line
          label_with_dots(I18n.t(key))
        end
      )
    end

    def signature_confirmation?
      event.signature_confirmation? && event.signature_confirmation_text?
    end

    def location_and_date
      [Event::Date.human_attribute_name(:location),
        Event::Date.model_name.human].join(" / ")
    end

    def contact_address
      [*contact_name_lines, *contact_postal_address_lines].compact_blank.join(", ")
    end

    def contact_name_lines
      return [] unless contact_attribute_visible?(:name)

      [contact.company_name, contact.full_name]
    end

    def contact_postal_address_lines
      return [] unless contact_attribute_visible?(:address)

      [*contact.address&.split("\n"), "#{contact.zip_code} #{contact.town}".strip]
    end

    def contact_email
      contact.email if contact_attribute_visible?(:email)
    end

    def contact_attribute_visible?(attr)
      event.contact_attribute_visible?(attr)
    end

    def label_with_dots(content)
      text content
      move_down_line
      text "." * 55
    end
  end
end
