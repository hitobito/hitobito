#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Pdf::List
  class People < Section
    def render
      bounding_box([bounds.left, bounds.top], width: bounds.width, height: bounds.height - 5.mm) do
        move_down_line 40; # first page has a header
        table(contactables.map { |p| person_row(p) }.unshift(table_header))
      end
    end

    private

    def table_header
      [
        I18n.t("people.print.name"),
        I18n.t("people.print.address"),
        I18n.t("people.print.email"),
        I18n.t("people.print.home_phone"),
        I18n.t("people.print.mobile_phone"),
      ]
    end

    def person_row(person)
      [
        person.person_name,
        address(person),
        person.email,
        phone_numbers(person, %w[Privat]),
        phone_numbers(person, %w[Mobil]),
      ]
    end

    def address(person)
      "#{person.address}, #{person.zip_code} #{person.town}"
    end

    def phone_numbers(person, labels)
      person.phone_numbers.where(label: labels).map { |phone| phone.number }.join("\n")
    end

    def table(data)
      pdf.table(data, header: true) do
        rows(0..data.length).borders = []
        cells.padding = [1, 1, 1, 5]
        cells.overflow = :shrink_to_fit
        cells.single_line = true
        row(0).font_style = :bold
        row(0).border_lines = [:solid]
      end
    end
  end
end
