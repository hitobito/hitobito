# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

# vCards for the CardDAV endpoint. Compared to the plain vCard export these
# carry a UID, which CardDAV requires to recognize a contact across address
# books, and a REV telling clients when the contact last changed.
class Carddav::Vcards < Export::Vcf::Vcards
  def generate_for(person)
    # RFC 6350 mandates CRLF line endings, the plain export separates with LF.
    vcard(person).to_s.gsub(/\r?\n/, "\r\n")
  end

  private

  def vcard(person)
    super.tap do |card|
      card << ::Vcard::DirectoryInfo::Field.create("UID", uid(person))
      card << ::Vcard::DirectoryInfo::Field.create("REV", rev(person))
    end
  end

  def uid(person)
    "hitobito-person-#{person.id}"
  end

  def rev(person)
    person.updated_at.utc.strftime("%Y%m%dT%H%M%SZ")
  end
end
