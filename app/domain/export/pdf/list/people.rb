#  Copyright (c) 2012-2026, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Pdf::List
  class People < Section
    def render
      preload_phone_numbers
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
        I18n.t("people.print.mobile_phone")
      ]
    end

    def person_row(person)
      [
        person.person_name(:list),
        address(person),
        person.email,
        home_phone_numbers(person),
        mobile_phone_numbers(person)
      ]
    end

    def address(person)
      "#{person.address}, #{person.zip_code} #{person.town}"
    end

    def preload_phone_numbers
      ActiveRecord::Associations::Preloader.new(
        records: phone_number_owners, associations: {phone_numbers: :category}
      ).call
    end

    # Override when the contactables are not the owners of the phone numbers.
    def phone_number_owners
      contactables.to_a
    end

    def home_phone_numbers(person)
      phone_number_lines(person.phone_numbers.select(&:home?))
    end

    def mobile_phone_numbers(person)
      phone_number_lines(person.phone_numbers.select(&:mobile?))
    end

    def phone_number_lines(phone_numbers)
      phone_numbers.map(&:number).join("\n")
    end

    def table(data)
      pdf.table(data, header: true) do
        rows(0..data.length).borders = []
        cells.padding = [1, 5, 1, 0]
        cells.overflow = :shrink_to_fit
        cells.single_line = true
        row(0).font_style = :bold
        row(0).border_lines = [:solid]
      end
    end
  end
end
