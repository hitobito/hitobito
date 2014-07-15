# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Pdf::Participation
  class PersonAndEvent < Section
    def render
      first_page_section do
        heading do
          render_boxed(-> { text human_participant_name, style: :bold },
                       -> { text human_event_name, style: :bold })
        end

        move_down_line
        render_boxed(-> { render_section(Person) },
                     -> { render_section(Event) }, 10)
      end
    end

    private

    # decrease size of section by 10
    def section_size
      super - 10
    end

    class Person < Section
      def render
        text person.first_name, person.last_name, style: :bold
        text person.address
        text person.zip_code, person.town
        move_down_line

        phone_numbers.each { |number| text number.to_s }
        text person.email
        move_down_line

        [:birthday, :j_s_number].each { |attr| labeled_attr(attr) }
        move_down_line

        originating_groups.each { |group| text group.to_s }
      end

      private

      def person_attributes
        [:birthday]
      end

      # TODO see 7304
      def originating_groups
        ['Schar: Jubla Ratatouille', 'Jubla-Kanton: SGAIARGL']
      end

      def phone_numbers
        person.phone_numbers.where(label: %w(Privat Mobil))
      end
    end

    class Event < Section
      def render
        text event, style: :bold
        move_down_line

        text event.number
        text event.kind if event_with_kind?
        labeled_attr(:cost)
        move_down_line

        text [human_event_name, dates_label.downcase].join, style: :bold
        render_dates
        stroke_bounds
      end

      private

      def dates_label
        human_attribute_name(:dates, event)
      end

      def render_dates(count = 3)
        height = 80 / count
        event.dates.limit(count).each_with_index do |date, index|
          bounding_box([0, cursor], width: bounds.width, height: height)  do
            date_with_index = [dates_label, index + 1].join(' ')

            shrinking_text_box "#{date_with_index} #{date.label_and_location}\n#{date.duration}"
          end
        end
      end
    end

  end
end
