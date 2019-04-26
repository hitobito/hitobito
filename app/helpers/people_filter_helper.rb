#  Copyright (c) 2012-2018, Schweizer Blasmusikverband. This file is part of
#  hitobito_sbv and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sbv.

module PeopleFilterHelper

  def people_filter_attribute_forms(filter, types)
    return unless filter

    filter.args.each_with_index.map do |(_k, attr), i|
      people_filter_attribute_form(attr, i)
    end.join.html_safe
  end

  def people_filter_attribute_types
    attributes = Person.filter_attrs_list.collect(&:second).collect(&:to_s)
    Person.columns_hash.slice(*attributes).transform_values { |v| v.type }
  end

  def people_filter_attribute_form_template
    people_filter_attribute_form(nil, 0, disabled: :disabled)
  end

  # rubocop:disable AbcSize, MethodLength
  def people_filter_attribute_form(attr, count, html_options = {})
    key, constraint, value = attr.to_h.symbolize_keys.slice(:key, :constraint, :value).values
    type = people_filter_attribute_types[key]
    time = (Time.zone.now.to_f * 1000).to_i + count

    filters = [[t('.match'), :match], [t('.equal'), :equal]]
    if key.blank? || type == :integer
      filters += [[t('.smaller'), :smaller], [t('.greater'), :greater]]
    end

    content_tag(:div, class: 'people_filter_attribute_form controls controls-row') do
      content = hidden_field_tag("filters[attributes][#{time}][key]",
                                 key,
                                 disabled: attr.blank?,
                                 class: 'attribute_key_hidden_field')

      content << select(:filters, "attributes[#{time}][key]",
                        Person.filter_attrs_list,
                        { selected: key },
                        html_options.merge(disabled: true, class: 'span attribute_key_dropdown'))

      content << select(:filters, "attributes[#{time}][constraint]",
                        filters,
                        { selected: constraint },
                        html_options.merge(class: 'span2 attribute_constraint_dropdown'))

      content << text_field_tag("filters[attributes][#{time}][value]",
                                value,
                                html_options.merge(class: 'span2 attribute_value_input'))

      content << link_to(icon(:trash), '#',
                         class: 'remove_filter_attribute',
                         style: 'padding-left: 7px; line-height: 2em')
    end
  end

end
