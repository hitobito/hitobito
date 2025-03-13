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

      content << content_tag(:div, class: "flex-none") do
        select(:filters, "attributes[#{time}][constraint]",
               filters,
               {selected: constraint},
               html_options.merge(class:
                                    'attribute_constraint_dropdown
                                         ms-3 form-select form-select-sm', name: "filters[attributes][#{time}][constraint]"))
      end

      attribute_value_class = "form-control form-control-sm ms-3
                               #{(constraint == "blank") ? " invisible" : ""}
                               attribute_value_input #{(type == :date) ? " date" : ""}"
      content << content_tag(:div, class: "flex-none") do
        text_field_tag("filters[attributes][#{time}][value]",
          value,
          html_options.merge(class: attribute_value_class))
      end

  def people_filter_attribute_control(attr, count, html_options = {})
    Person::Filter::AttributeControl.new(self, attr, count, html_options).to_s
  end
end
