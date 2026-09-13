# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

# A single person, represented as a vCard resource inside the address book.
class Carddav::Resources::Contact < Carddav::Resources::Base
  CONTENT_TYPE = "text/vcard"

  attr_reader :person

  def initialize(address_book, person)
    super(address_book)
    @person = person
  end

  def href = Carddav::Hrefs.contact(person)

  def vcard
    @vcard ||= Carddav::Vcards.new.generate_for(person)
  end

  # Derived from the content, as a person's contact accounts change without
  # their own updated_at being touched.
  def etag
    @etag ||= %("#{Digest::MD5.hexdigest(vcard)}")
  end

  def properties
    {
      dav(:resourcetype) => ->(xml) {},
      dav(:getetag) => text_property(etag),
      dav(:getcontenttype) => text_property("#{CONTENT_TYPE}; charset=utf-8"),
      dav(:getlastmodified) => text_property(person.updated_at.httpdate),
      dav(:"current-user-privilege-set") => read_only_privileges,
      carddav(:"address-data") => ->(xml) { xml.text(vcard) }
    }
  end
end
