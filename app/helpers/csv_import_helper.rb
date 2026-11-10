#  Copyright (c) 2012-2026, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module CsvImportHelper
  def application_person_fields
    fields = Import::Person.fields
    fields = fields.reject { |field| field[:key] == "id" } unless @can_import_with_id
    fields.map { |field| OpenStruct.new(field) }
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

  def csv_import_attr_value(person, attr)
    if csv_import_people_of(person).any? { |p| p.imported_attributes.key?(attr) }
      format_attr(person, attr)
    else
      csv_import_stored_attr_value(person, attr)
    end
  end

  def csv_import_contact_account_value(person, key)
    contact = csv_import_contact_account(person, key)
    contact.value if contact && csv_import_contact_account_visible?(person, contact)
  end

  def csv_import_tag_values(person)
    return person.tag_list.to_s if can?(:show_tags, csv_import_stored_person(person))

    ActsAsTaggableOn::TagList.new(csv_import_people_of(person).flat_map(&:tags), parse: true).to_s
  end

  def csv_import_role_value(person, attr)
    role = person.roles.find { |r| r.group_id == group.id && r.type == @role_type.to_s }
    if role.new_record? || can?(:show, csv_import_stored_person(person))
      f(role.send(attr))
    else
      t("global.not_allowed")
    end
  end

  private

  def csv_import_people_of(person)
    @csv_import_people ||=
      importer.people.each_with_object({}.compare_by_identity) do |import_person, people|
        (people[import_person.person] ||= []) << import_person
      end
    @csv_import_people.fetch(person)
  end

  # Permissions must not take the roles into account that are added by the import.
  def csv_import_stored_person(person)
    return person if person.new_record?

    @csv_import_stored_people ||= Person
      .where(id: importer.people.map(&:person).select(&:persisted?).map(&:id))
      .preload_groups
      .index_by(&:id)
    @csv_import_stored_people.fetch(person.id)
  end

  def csv_import_stored_attr_value(person, attr)
    column = csv_import_column_class(attr).new(current_ability, model_class: Person)
    column.value_for(csv_import_stored_person(person), attr) do |target, target_attr|
      format_attr(target, target_attr)
    end
  end

  def csv_import_column_class(attr)
    registered = TableDisplay.table_display_columns.to_h.dig(Person.to_s, attr.to_s)
    return registered if registered

    if TableDisplays::People::ALWAYS_SHOWN_ATTRS.include?(attr.to_sym)
      TableDisplays::PublicColumn
    else
      TableDisplays::ShowFullColumn
    end
  end

  def csv_import_contact_account(person, key)
    [AdditionalEmail, PhoneNumber, SocialAccount].each do |model|
      category = Import::ContactAccountFields.new(model).category_for(key)
      return person.send(model.table_name).find { |c| c.category_id == category.id } if category
    end
    nil
  end

  def csv_import_contact_account_visible?(person, contact)
    stored_person = csv_import_stored_person(person)
    csv_import_people_of(person).any? { |p| p.imported_accounts.include?(contact) } ||
      can?(:show_details, stored_person) ||
      (contact.public? && can?(:show, stored_person))
  end
end
