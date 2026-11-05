# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module BlocklistEntriesHelper
  def blocklist_explanation
    attributes = person_attrs_sentence(Person::BlocklistDetector.hash_attrs)
    optional_attrs = Person::BlocklistDetector.optional_hash_attrs
    if optional_attrs.present?
      t(".explanation_optional",
        attributes:, optional_attributes: person_attrs_sentence(optional_attrs))
    else
      t(".explanation", attributes:)
    end
  end

  def format_blocklist_entry_hashed_attrs(entry)
    entry.hashed_attrs.map { Person.human_attribute_name(_1) }.join(", ")
  end

  private

  def person_attrs_sentence(attrs)
    attrs.map { Person.human_attribute_name(_1) }.to_sentence
  end
end
