# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

# The principal of the authenticated person, from which clients find the
# address books that person has access to.
class Carddav::Resources::Principal < Carddav::Resources::Base
  def href = Carddav::Hrefs.principal

  def properties
    {
      dav(:resourcetype) => ->(xml) {
        xml["d"].collection
        xml["d"].principal
      },
      dav(:displayname) => text_property(address_book.user.to_s),
      dav(:"current-user-privilege-set") => read_only_privileges
    }.merge(principal_properties)
  end
end
