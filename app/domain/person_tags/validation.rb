# frozen_string_literal: true

module PersonTags
  class Validation

    EMAIL_PRIMARY_INVALID='category_validation:email_primary_invalid'.freeze
    EMAIL_ADDITIONAL_INVALID='category_validation:email_additional_invalid'.freeze
    ADDRESS_INVALID='category_validation:address_invalid'.freeze
    INVALID_ADDRESS_OVERRIDE='category_validation:invalid_address_override'.freeze

    class << self

      def tag_names
        [EMAIL_PRIMARY_INVALID, EMAIL_ADDITIONAL_INVALID, ADDRESS_INVALID, INVALID_ADDRESS_OVERRIDE]
      end

      def list
        [email_primary_invalid,
         email_additional_invalid,
         address_invalid,
         invalid_address_override].compact
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
