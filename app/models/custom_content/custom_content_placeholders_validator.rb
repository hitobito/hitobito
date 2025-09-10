# frozen_string_literal: true

#  Copyright (c) 2012-2025, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# This validator checks if the placeholder is either in the body or the subject of the custom content
class CustomContent::CustomContentPlaceholdersValidator < ActiveModel::Validator
  def validate(record)
    return unless Globalized.globalize_inputs?

    languages = [I18n.locale] + Settings.application.languages.keys.excluding(I18n.locale)
    languages.each do |lang|
      subject_body = [record.send("subject_#{lang}"), record.send("body_#{lang}")]

      next if subject_body.all?(&:blank?)

      attribute = (lang == I18n.locale) ? :body : :"body_#{lang}"
      record.placeholders_required_list.each do |placeholder|
        unless subject_body.any? { |str| str.to_s.include?(record.placeholder_token(placeholder)) }
          record.errors.add(attribute, :placeholder_missing, placeholder: record.placeholder_token(placeholder))
        end
      end
    end
  end
end
