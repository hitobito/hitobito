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

  def csv_import_attrs
    Import::Person.person_attributes.
      select { |f| field_mappings.values.include?(f[:key].to_s) }.
      map { |f| f[:key]  }
  end

  def csv_import_contact_account_attrs(&block)
    [
      Import::ContactAccountFields.new(AdditionalEmail),
      Import::ContactAccountFields.new(PhoneNumber),
      Import::ContactAccountFields.new(SocialAccount)
    ].each do |caf|
      caf.fields.select { |f| field_mappings.values.include?(f[:key].to_s) }.
                 each(&block)
    end
  end

  def csv_import_contact_account_value(p, key)
    parts = key.split('_')
    key = parts.last
    assoc = parts[0..-2].join('_').pluralize
    contact = p.send(assoc).find { |c| c.label.downcase == key }
    contact && contact.value
  end

end
