# frozen_string_literal: true

#  Copyright (c) 2012-2020, Die Mitte Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Contactable
  class EmailValidator
    def initialize(block: false)
      @block = block
    end

    def validate_people
      Person.all.includes(:additional_emails).find_each do |p|
        validate_emails(p, p.email, kind: :primary)
        validate_emails(p, *p.additional_emails.map(&:email), kind: :additional)
      end
    end

    private

    def validate_emails(person, *emails, kind:)
      invalid_emails = emails.select { invalid?(_1) }
      tag_and_block!(person, *invalid_emails, kind:) if invalid_emails.present?
    end

    def invalid?(email)
      email.present? && !Truemail.valid?(email)
    end

    def tag_and_block!(person, *invalid_emails, kind:)
      block_invalid!(*invalid_emails)
      tag_invalid!(person, invalid_emails.join(" "), kind)
    end

    def block_invalid!(*invalid_emails)
      return unless @block && FeatureGate.enabled?("email.bounces")

      invalid_emails.each { Bounce.setup(_1)&.block! }
    end

    def tag_invalid!(person, invalid_email, kind)
      InvalidEmailTagger.new(person, invalid_email, kind).tag!
    end
  end
end
