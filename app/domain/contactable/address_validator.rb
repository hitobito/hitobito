# frozen_string_literal: true

#  Copyright (c) 2012-2024, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

module Contactable
  class AddressValidator
    def validate_people
      scope.includes(:tags).find_each do |person|
        next unless should_be_validated?(person)

        if invalid?(person)
          tag_invalid!(person, person.address)
        elsif invalid_tagging_exists?(person)
          remove_invalid_tagging!(person)
        end
      end

      Person.tagged_with(invalid_tag)
    end

    def scope
      Person
        .where(country: Settings.addresses.imported_countries)
        .where.not(street: "")
        .where.not(zip_code: "")
    end

    private

    def should_be_validated?(person)
      person.tags.exclude?(invalid_override_tag)
    end

    def invalid?(person)
      street = person.street
      number = person.housenumber
      addresses = Address.for(person.zip_code, street)
      addresses.empty? || invalid_number?(addresses, number)
    end

    def invalid_number?(addresses, number)
      number && addresses.none? { |a| a.numbers.include?(number) }
    end

    def parse(string)
      Address::Parser.new(string).parse
    end

    def tag_invalid!(person, invalid_address)
      ActsAsTaggableOn::Tagging
        .find_or_create_by!(taggable: person, context: :tags, tag: invalid_tag)
        .tap do |t|
          t.update!(hitobito_tooltip: invalid_address)
        end
    end

    def remove_invalid_tagging!(person)
      ActsAsTaggableOn::Tagging
        .destroy_by(taggable: person,
          tag: invalid_tag)
    end

    def invalid_tagging_exists?(person)
      ActsAsTaggableOn::Tagging
        .exists?(taggable: person,
          tag: invalid_tag)
    end

    def invalid_tag
      @invalid_tag ||=
        PersonTags::Validation.address_invalid(create: true)
    end

    def invalid_override_tag
      @invalid_override_tag ||=
        PersonTags::Validation.invalid_address_override
    end
  end
end
