#  Copyright (c) 2012-2026, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module CsvImportHelper
  def application_person_fields
    Import::Person.fields.map { |field| OpenStruct.new(field) }
  end

  def csv_field_documentation(field, values)
    if values.is_a?(Hash)
      values = safe_join(values, tag.br) do |value, description|
        content_tag(:em, value) + h(" - #{description}")
      end
    end

    content_tag(:dt, t("activerecord.attributes.person.#{field}")) +
      content_tag(:dd, values)
  end

  def csv_import_attrs
    Import::Person.person_attributes
      .select { |f| field_mappings.value?(f[:key].to_s) }
      .pluck(:key)
  end

  def csv_import_contact_account_attrs(&block)
    [
      Import::ContactAccountFields.new(AdditionalEmail),
      Import::ContactAccountFields.new(PhoneNumber),
      Import::ContactAccountFields.new(SocialAccount)
    ].each do |caf|
      caf.fields.select { |f| field_mappings.value?(f[:key].to_s) }
        .each(&block)
    end
  end

  def csv_import_contact_account_value(p, key)
    [AdditionalEmail, PhoneNumber, SocialAccount].each do |model|
      category = Import::ContactAccountFields.new(model).category_for(key)
      next unless category

      contact = p.send(model.table_name).find { |c| c.category_id == category.id }
      return contact&.value
    end
    nil
  end

  def csv_import_tag_values(p)
    p.tag_list.to_s
  end

  def csv_import_role_value(p, attr)
    value = p.roles.find { |r| r.type == @role_type.to_s }.send(attr)
    f(value)
  end
end
