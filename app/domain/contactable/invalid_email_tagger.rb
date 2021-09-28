# frozen_string_literal: true

#  Copyright (c) 2012-2020, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

module Contactable
  class InvalidEmailTagger
    attr_reader :person, :email, :email_kind

    def initialize(person, email, email_kind)
      @person = person
      @email = email
      @email_kind = email_kind
    end

    def tag!
      tag = send(:"invalid_tag_#{email_kind}")
      ActsAsTaggableOn::Tagging
        .find_or_create_by!(taggable: person,
                            hitobito_tooltip: email,
                            context: :tags,
                            tag: tag)
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
