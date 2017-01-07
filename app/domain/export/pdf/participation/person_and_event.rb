# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Pdf::Participation
  class PersonAndEvent < Section

    class Person < Section

      def render
        render_address
        move_down_line

        phone_numbers.each { |number| text number.to_s }
        text person.email
        move_down_line

        person_attributes.each { |attr| labeled_attr(person, attr) }
        move_down_line
        stroke_bounds
      end

      private

      def render_address
        text person.person_name, style: :bold
        text person.address
        text address_details
      end

      def address_details
        [person.zip_code, person.town]
      end

      def person_attributes
        [:birthday]
      end

      def phone_numbers
        person.phone_numbers.where(label: %w(Privat Mobil))
      end
    end

    class Event < Section
      def render
        text event, style: :bold
        move_down_line

        render_details
        move_down_line

        render_dates
        move_down_line
        stroke_bounds
      end

      private

      def render_details
        text event.number
        text event.kind if event_with_kind?
        labeled_attr(event, :cost)
      end

      def render_dates(count = 3)
        text dates_label, style: :bold
        height = 80 / count
        event.dates.limit(count).each do |date|
          bounding_box([0, cursor], width: bounds.width, height: height) do
            text "#{date.label_and_location}\n#{date.duration}"
          end
        end
      end

      def dates_label
        human_attribute_name(:dates, event)
      end
    end

    class_attribute :person_section

    self.person_section = Person

    def render
      heading do
        render_columns(-> { text human_participant_name, style: :bold },
                       -> { text human_event_name, style: :bold })
      end

      render_columns(-> { render_section(person_section) },
                     -> { render_section(Event) })
    end

    private

    # decrease size of section by 10
    def section_size
      super - 10
    end

  end
end
