# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

module PersonTags
  class Validation
    EMAIL_PRIMARY_INVALID = "category_validation:email_primary_invalid"
    EMAIL_ADDITIONAL_INVALID = "category_validation:email_additional_invalid"
    ADDRESS_INVALID = "category_validation:address_invalid"
    INVALID_ADDRESS_OVERRIDE = "category_validation:invalid_address_override"
    POST_ADDRESS_CHECK_INVALID = "category_validation:post_address_check_invalid"

    class << self
      def tag_names
        [
          EMAIL_PRIMARY_INVALID,
          EMAIL_ADDITIONAL_INVALID,
          ADDRESS_INVALID,
          INVALID_ADDRESS_OVERRIDE,
          POST_ADDRESS_CHECK_INVALID
        ]
      end

      def list
        [
          email_primary_invalid,
          email_additional_invalid,
          address_invalid,
          invalid_address_override,
          post_address_check_invalid
        ].compact
      end

      def email_primary_invalid(create: false)
        find(EMAIL_PRIMARY_INVALID, create: create)
      end

      def email_additional_invalid(create: false)
        find(EMAIL_ADDITIONAL_INVALID, create: create)
      end

      def address_invalid(create: false)
        find(ADDRESS_INVALID, create: create)
      end

      def invalid_address_override(create: false)
        find(INVALID_ADDRESS_OVERRIDE, create: create)
      end

      def post_address_check_invalid(create: true)
        find(POST_ADDRESS_CHECK_INVALID, create:)
      end

      private

      def find(tag, create: false)
        if create
          tag_class.find_or_create_by!(name: tag)
        else
          tag_class.find_by(name: tag)
        end
      end

      def tag_class
        ActsAsTaggableOn::Tag
      end
    end
  end
end
