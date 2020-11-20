# frozen_string_literal: true

#  Copyright (c) 2012-2020, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

module Contactable
  class AddressValidator

    def validate_people
      Person.find_each do |person|
        next unless should_be_validated?(person)

        if invalid?(person.address, person.zip_code, person.town)
          tag_invalid!(person, person.address)
        end
      end

      Person.tagged_with(invalid_tag)
    end

    private

    def should_be_validated?(person)
      Settings.addresses.imported_countries.include?(person.country) &&
        person.tags.exclude?(invalid_override_tag)
    end

    def invalid?(address, zip_code, town)
      Address.where(street_short: address, zip_code: zip_code, town: town).empty?
    end

    def tag_invalid!(person, invalid_address, kind = :primary)
      ActsAsTaggableOn::Tagging
        .find_or_create_by!(taggable: person,
                            hitobito_tooltip: invalid_address,
                            context: :tags,
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
