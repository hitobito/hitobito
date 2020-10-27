# frozen_string_literal: true

module PersonTags
  class Validation

    EMAIL_PRIMARY_INVALID='category_validation:email_primary_invalid'.freeze
    EMAIL_ADDITIONAL_INVALID='category_validation:email_additional_invalid'.freeze

    class << self

      def tag_names
        [EMAIL_PRIMARY_INVALID, EMAIL_ADDITIONAL_INVALID]
      end

      def list
        [email_primary_invalid, email_additional_invalid].compact
      end

      def email_primary_invalid(create: false)
        find(EMAIL_PRIMARY_INVALID, create: create)
      end

      def email_additional_invalid(create: false)
        find(EMAIL_ADDITIONAL_INVALID, create: create)
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
