# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

# Base class of the resources the CardDAV endpoint exposes.
#
# Subclasses declare the WebDAV properties they support as lambdas that write
# the value of the property into the XML being built. Evaluating them lazily
# keeps the expensive ones - everything derived from a contact's vCard - out of
# the way as long as no client asks for them.
class Carddav::Resources::Base
  attr_reader :address_book

  def initialize(address_book)
    @address_book = address_book
  end

  # The resources contained in this one, returned for a PROPFIND with Depth: 1.
  def members
    []
  end

  # If present, the response for this resource carries a bare status instead of
  # the requested properties.
  def status
    nil
  end

  private

  def dav(name) = Carddav::Property.dav(name)

  def carddav(name) = Carddav::Property.carddav(name)

  def calendarserver(name) = Carddav::Property.calendarserver(name)

  def href_property(href)
    ->(xml) { xml["d"].href(href) }
  end

  def text_property(value)
    ->(xml) { xml.text(value.to_s) }
  end

  # Tells a client whom it is authenticated as. Only on the collections, as
  # that is where clients look for it.
  def current_user_principal
    {dav(:"current-user-principal") => href_property(Carddav::Hrefs.principal)}
  end

  # Additional properties of the resources a client starts its discovery at.
  def principal_properties
    current_user_principal.merge(
      dav(:"principal-URL") => href_property(Carddav::Hrefs.principal),
      carddav(:"addressbook-home-set") => href_property(Carddav::Hrefs.home)
    )
  end

  def read_only_privileges
    ->(xml) do
      xml["d"].privilege { xml["d"].read_ }
      xml["d"].privilege { xml["d"].send(:"read-current-user-privilege-set") }
    end
  end
end
