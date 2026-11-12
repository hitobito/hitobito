# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# Postal address as printed on letters and labels. Names come as prepared lines.
#
# Addressing rules of Swiss Post ("Briefgestaltung von A–Z",
# https://www.post.ch/-/media/portal-opp/pm/dokumente/briefe-spezifikation-gestaltung.pdf):
# - at least three, at most six lines, no blank lines in between
# - second last line: street with house number or postbox
# - last line: zip code and town
# - items with both domicile and postbox are delivered to the postbox
#
# Addressing rules of the Universal Postal Union ("Postal Addressing Systems",
# https://www.upu.int/UPU/media/upu/documents/PostCode/AddressElementsFormattingAnInternationalAdressEn.pdf):
# - the country of destination is printed on the last line, in capital letters, in the
#   language of the dispatching country or an internationally recognized language
PostalAddress::Printed = Data.define(:salutation, :names, :care_of, :addition, :street,
  :housenumber, :postbox, :zip_code, :town, :country) do
  def initialize(salutation: nil, **)
    super
  end

  def lines
    address = self
    address = address.with_addition_after_care_of if address.exceeds_max_lines?
    address = address.with_names_on_one_line if address.exceeds_max_lines?
    address = address.without_street_if_postbox if address.exceeds_max_lines?
    address.all_lines
  end

  def fits? = lines.size <= PostalAddress::Printed::MAX_LINES

  def all_lines
    [salutation, *names, care_of, addition, street_line, postbox, zip_town, country_line]
      .flat_map { |line| line.to_s.split("\n") }
      .map(&:strip)
      .compact_blank
  end

  def street_line = join_present(street, housenumber)

  def zip_town = join_present(zip_code, town)

  def country_line
    Countries.label(country).upcase unless country.blank? || domestic?
  end

  def exceeds_max_lines? = all_lines.size > PostalAddress::Printed::MAX_LINES

  def with_addition_after_care_of
    return self if care_of.blank? || addition.blank?

    with(care_of: "#{care_of.strip}, #{addition.strip}", addition: nil)
  end

  def with_names_on_one_line
    with(names: names.map { |name| join_present(*name.to_s.split("\n"), separator: ", ") })
  end

  def without_street_if_postbox
    postbox.present? ? with(street: nil, housenumber: nil) : self
  end

  private

  def join_present(*parts, separator: " ")
    parts.map { |part| part.to_s.strip }.compact_blank.join(separator)
  end

  def domestic? = country.to_s.casecmp?(Settings.countries.prioritized.first)
end

PostalAddress::Printed::MAX_LINES = 6
