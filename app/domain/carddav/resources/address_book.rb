# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

# The address book collection itself, holding one contact per person the
# authenticated person may see.
class Carddav::Resources::AddressBook < Carddav::Resources::Base
  REPORTS = %w[addressbook-query addressbook-multiget].freeze

  def href = Carddav::Hrefs.address_book

  def properties
    {
      dav(:resourcetype) => ->(xml) {
        xml["d"].collection
        xml["card"].addressbook
      },
      dav(:displayname) => text_property(address_book.name),
      dav(:"supported-report-set") => supported_report_set,
      dav(:"current-user-privilege-set") => read_only_privileges
    }.merge(address_book_properties).merge(current_user_principal)
  end

  def members
    address_book.people.collect { |person| contact(person) }
  end

  def contact(person)
    Carddav::Resources::Contact.new(address_book, person)
  end

  private

  def address_book_properties
    {
      calendarserver(:getctag) => text_property(address_book.ctag),
      carddav(:"addressbook-description") => text_property(address_book.description)
    }
  end

  def supported_report_set
    ->(xml) do
      REPORTS.each do |name|
        xml["d"].send(:"supported-report") do
          xml["d"].report { xml["card"].send(name) }
        end
      end
    end
  end
end
