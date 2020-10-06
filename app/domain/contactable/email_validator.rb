# frozen_string_literal: true

module Contactable
  class EmailValidator

    def validate_people
      Person.all.includes(:additional_emails).find_each do |p|
        if invalid?(p.email)
          tag_invalid!(p, p.email)
        end
        validate_additional_emails(p)
      end
    end

    private

    def validate_additional_emails(person)
      additional_emails = person.additional_emails.pluck(:email)
      invalid_emails = additional_emails.select do |a|
        invalid?(a)
      end

      if invalid_emails.present?
        tag_invalid!(person, invalid_emails.join(' '), :additional)
      end
    end

    def invalid?(email)
      !Truemail.valid?(email)
    end

    def tag_invalid!(person, invalid_email, kind = :primary)
      ActsAsTaggableOn::Tagging
        .find_or_create_by!(taggable: person,
                            hitobito_tooltip: invalid_email,
                            context: :tags,
                            tag: send("invalid_tag_#{kind}"))
    end

    def invalid_tag_primary
      @invalid_tag_primary ||=
        PersonTags::Validation.email_primary_invalid(create: true)
    end

    def invalid_tag_additional
      @invalid_tag_additional ||=
        PersonTags::Validation.email_additional_invalid(create: true)
    end
  end
end
