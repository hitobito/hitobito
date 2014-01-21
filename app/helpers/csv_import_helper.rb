# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module CsvImportHelper

  def application_person_fields
    Import::Person.fields.map { |field| OpenStruct.new(field) }
  end

  def csv_field_documentation(field, values)
    if values.is_a?(Hash)
      values = safe_join(values, tag(:br)) do |value, description|
        content_tag(:em, value) + h(" - #{description}")
      end
    end

    content_tag(:dt, t("activerecord.attributes.person.#{field}")) +
    content_tag(:dd, values)
  end

end
