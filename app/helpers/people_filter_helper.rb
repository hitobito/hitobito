#  Copyright (c) 2012-2018, Schweizer Blasmusikverband. This file is part of
#  hitobito_sbv and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sbv.

module PeopleFilterHelper
  def people_filter_attributes_for_select
    Person.filter_attrs.transform_values { |v| v[:label] }.invert.sort
  end

  def people_filter_types_for_data_attribute
    Person.filter_attrs.transform_values { |v| v[:type] }.to_h.to_json
  end

  def people_filter_attribute_forms(filter)
    return unless filter

    filter.args.each_with_index.map do |(_k, attr), i|
      people_filter_attribute_form(attr, i)
    end.join.html_safe
  end

  def people_filter_attribute_form_template
    people_filter_attribute_form(nil, 0, disabled: :disabled)
  end

  def people_filter_attribute_form(attr, count, html_options = {}) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    key, constraint, value = attr.to_h.symbolize_keys.slice(:key, :constraint, :value).values
    type = Person.filter_attrs[key.to_sym][:type] if key
    time = (Time.zone.now.to_f * 1000).to_i + count

    content_tag(:div,
      class: 'people_filter_attribute_form d-flex align-items-center
                        justify-content-between mb-2 controls controls-row') do
      content = attribute_key_hidden_field(key, time, disabled: attr.blank?)
      content << attribute_key_field(key, time, html_options)
      content << attribute_constraint_field(key, constraint, type, time, html_options)

      attribute_value_class = "#{(constraint == "blank") ? " invisible" : ""} attribute_value_input #{(type == :date) ? " date" : ""}"
      content << content_tag(:div, class: "col") do
        if type
          send(:"#{type}_field", time, attribute_value_class, value, html_options)
        else
          all_field_types(time, attribute_value_class, value, html_options)
        end
      end

      content << link_to(icon(:"trash-alt", filled: false), "#",
        class: "remove_filter_attribute col lh-lg ms-5")
    end
  end

  def attribute_key_hidden_field(key, time, disabled: false)
    hidden_field_tag("filters[attributes][#{time}][key]",
      key,
      disabled: disabled,
      class: "attribute_key_hidden_field")
  end

  def attribute_key_field(key, time, html_options)
    content_tag(:div, class: "col") do
      select_tag("filters[attributes][#{time}][key]",
        options_from_collection_for_select(people_filter_attributes_for_select, :last, :first, key),
        html_options.merge(disabled: true,
          class: 'attribute_key_dropdown form-select
                                                form-select-sm'))
    end
  end

  def attribute_constraint_field(key, constraint, type, time, html_options)
    filters = [[t(".equal"), :equal]]
    if type != :integer && type != :date && type != :country_select
      filters += [[t(".match"), :match], [t(".not_match"), :not_match]]
    end
    if key.blank? || type == :integer
      filters += [[t(".smaller"), :smaller], [t(".greater"), :greater]]
    end
    if key.blank? || type == :date
      filters += [[t(".before"), :before], [t(".after"), :after]]
    end

    filters += [[t(".blank"), :blank]]

    content_tag(:div, class: "col") do
      select_tag("filters[attributes][#{time}][constraint]",
        options_from_collection_for_select(filters, :last, :first, constraint),
        html_options.merge(class:
                           'attribute_constraint_dropdown
                                       ms-3 form-select form-select-sm'))
    end
  end

  def all_field_types(time, attribute_value_class, value, html_options)
    safe_join([
      string_field(time, attribute_value_class, value, html_options),
      country_select_field(time, attribute_value_class, value, html_options),
      integer_field(time, attribute_value_class, value, html_options),
      date_field(time, attribute_value_class, value, html_options)
    ])
  end

  ### FITLER FIELD TYPES

  def string_field(time, attribute_value_class, value, html_options)
    text_field_tag("filters[attributes][#{time}][value]",
      value,
      html_options.merge(class: "form-control form-control-sm string_field #{attribute_value_class}"))
  end

  def country_select_field(time, attribute_value_class, value, html_options)
    country_select("filters[attributes][#{time}]",
      "value",
      {priority_countries: Settings.countries.prioritized,
       selected: value,
       include_blank: ""},
      html_options.merge(class: "form-select form-select-sm country_select_field #{attribute_value_class}"))
  end

  def integer_field(time, attribute_value_class, value, html_options)
    text_field_tag("filters[attributes][#{time}][value]",
      value,
      html_options.merge(class: "form-control form-control-sm integer_field #{attribute_value_class}", type: "number"))
  end

  def date_field(time, attribute_value_class, value, html_options)
    text_field_tag("filters[attributes][#{time}][value]",
      value,
      html_options.merge(class: "form-control form-control-sm date date_field #{attribute_value_class}"))
  end
end
