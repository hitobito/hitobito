# frozen_string_literal: true

#  Copyright (c) 2012-2025, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# This validator checks if the placeholder is either in the body or the subject of the custom content
class CustomContent::CustomContentPlaceholdersValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    subject = record.subject
    if record.globalize_attribute_names.include? attribute
      locale = attribute.match(Globalized::ATTRIBUTE_LOCALE_REGEX)[:locale]
      subject = record.send(:"subject_#{locale}")
    end

    return if value.blank? && subject.blank?

    record.placeholders_required_list.each do |placeholder|
      unless [subject, value.to_s].any? { |str| str.to_s.include?(record.placeholder_token(placeholder)) }
        record.errors.add(attribute, :placeholder_missing, placeholder: record.placeholder_token(placeholder))
      end
    end
  end
end
