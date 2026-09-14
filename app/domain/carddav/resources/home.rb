# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

# The addressbook home set, the collection holding the address books of the
# authenticated person. hitobito offers exactly one.
class Carddav::Resources::Home < Carddav::Resources::Base
  def href = Carddav::Hrefs.home

  def properties
    {
      dav(:resourcetype) => ->(xml) { xml["d"].collection },
      dav(:displayname) => text_property(address_book.name),
      dav(:"current-user-privilege-set") => read_only_privileges
    }.merge(current_user_principal)
  end

  def members
    [Carddav::Resources::AddressBook.new(address_book)]
  end
end
