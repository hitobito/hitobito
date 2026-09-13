# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

# A WebDAV property, identified by the namespace and the name of its XML
# element. Used both for the properties a resource offers and for the ones a
# client asks for, so that the two can simply be compared.
Carddav::Property = Struct.new(:namespace, :name) do
  def self.dav(name) = new(Carddav::Namespaces::DAV, name.to_s)

  def self.carddav(name) = new(Carddav::Namespaces::CARDDAV, name.to_s)

  def self.calendarserver(name) = new(Carddav::Namespaces::CALENDARSERVER, name.to_s)
end
