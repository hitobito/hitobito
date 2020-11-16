# frozen_string_literal: true
#
#  Copyright (c) 2012-2020, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

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
      InvalidEmailTagger.new(person, invalid_email, kind).tag!
    end
  end
end
