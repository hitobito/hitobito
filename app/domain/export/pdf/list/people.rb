# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Pdf::List
  class People < Section

    def render
      pdf.table(
        contactables.map {|p| person_row(p)}.unshift(table_header) , :header => true, :cell_style => {:borders => [], :inline_format => true})
    end

    private

    def table_header
      ["<b>Name</b>", "<b>Adresse</b>", "<b>E-Mail</b>", "<b>Privat</b>", "<b>Mobil</b>"]
    end

    def person_row(person)
      [person.person_name, address(person), person.email, phone_numbers(person, %w(Privat)), phone_numbers(person, %w(Mobil))]
    end

    def address(person)
      "#{person.address}, #{person.zip_code} #{person.town}"
    end

    def phone_numbers(person, labels)
      person.phone_numbers.where(label: labels).map{|phone| phone.number}.join("\n")
    end

  end
end
