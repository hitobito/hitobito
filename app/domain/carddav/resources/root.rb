# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

# The entry point of the endpoint. Clients are pointed here by service
# discovery and look up the principal of the authenticated person from here.
class Carddav::Resources::Root < Carddav::Resources::Base
  def href = Carddav::Hrefs.root

  def properties
    {
      dav(:resourcetype) => ->(xml) { xml["d"].collection },
      dav(:displayname) => text_property(Settings.application.name),
      dav(:"current-user-privilege-set") => read_only_privileges
    }.merge(principal_properties)
  end

  def members
    [Carddav::Resources::Principal.new(address_book)]
  end
end
