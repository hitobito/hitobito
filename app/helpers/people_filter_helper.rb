#  Copyright (c) 2012-2018, Schweizer Blasmusikverband. This file is part of
#  hitobito_sbv and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sbv.

module PeopleFilterHelper
  def people_filter_qualification_kind_options(filter)
    list = QualificationKind.list.without_deleted.map { |qualification| [qualification.id, qualification.label] }
    options_from_collection_for_select(list, :first, :second, people_filter_selected_values(filter, :qualification_kind_ids))
  end

  def people_filter_qualification_validity_options(filter)
    list = %w[active reactivateable not_active_but_reactivateable all none only_expired].map do |option|
      [option, t("people_filters.qualification.validity_label.#{option}")]
    end
    options_from_collection_for_select(list, :first, :second, people_filter_selected_values(filter, :validity))
  end

  def people_filter_role_options(filter)
    list = Role::TypeList.new(group.class).role_types
      .flat_map { |layer, hash| hash.flat_map { |g, roles| roles.map { |r| [r.id, [layer, g, r.model_name.human].uniq.join(" -> ")] } } }

    options_from_collection_for_select(list, :first, :second, people_filter_selected_values(filter, :role_type_ids))
  end

  def people_filter_role_kind_options(filter)
    list = Person::Filter::Role::KINDS.map { |kind| [t("people_filters.form.filters_role_kind.#{kind}"), kind] }
    options_from_collection_for_select(list, :second, :first, people_filter_selected_values(filter, :kinds))
  end

  def people_filter_tags_options(filter_chain)
    list = PersonTags::Translator.new.possible_tags

    {
      present: options_from_collection_for_select(list, :second, :first, people_filter_selected_values(filter_chain[:tag], :names)),
      absent: options_from_collection_for_select(list, :second, :first, people_filter_selected_values(filter_chain[:tag_absence], :names))
    }
  end

  def people_filter_selected_values(filter, key)
    filter.to_hash[key] if filter.present?
  end

  def people_filter_attributes_for_select
    Person.filter_attrs.transform_values { |v| v[:label] }.invert.sort
  end

  def people_filter_types_for_data_attribute
    Person.filter_attrs.transform_values { |v| v[:type] }.to_h.to_json
  end

  def people_filter_value(filter, key)
    filter.args[key.to_sym] if filter.present?
  end

  def people_filter_attribute_controls(filter)
    return unless filter

    filter.args.each_with_index.map do |(_k, attr), i|
      people_filter_attribute_control(attr, i)
    end.join.html_safe
  end

  def people_filter_attribute_value(key, value)
    if key == "gender"
      Person.new(gender: value).gender_label
    elsif %w[true false].include?(value)
      f(ActiveModel::Type::Boolean.new.cast(value))
    else
      f(value)
    end
  end

  def people_filter_attribute_control_template
    people_filter_attribute_control(nil, 0, disabled: :disabled)
  end

  def people_filter_attribute_control(attr, count, html_options = {})
    Person::Filter::AttributeControl.new(self, attr, count, html_options).to_s
  end
end
