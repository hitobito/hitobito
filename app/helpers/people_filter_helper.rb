#  Copyright (c) 2012-2018, Schweizer Blasmusikverband. This file is part of
#  hitobito_sbv and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sbv.

module PeopleFilterHelper

  def people_filter_attribute_forms(filter)
    return unless filter

    filter.args.each_with_index.map do |(_k, attr), i|
      people_filter_attribute_form(attr, i)
    end.join.html_safe
  end

  def people_filter_attribute_form_template
    people_filter_attribute_form(nil, 0, disabled: :disabled)
  end

  # rubocop:disable AbcSize, MethodLength
  def people_filter_attribute_form(attr = nil, count = 0, html_options = {})
    time = (Time.zone.now.to_f * 1000).to_i + count

    content_tag(:div, class: 'people_filter_attribute_form controls controls-row') do
      content = select(:filters, "attributes[#{time}][key]",
                       Person.filter_attrs_list,
                       { selected: (attr[:key] if attr) },
                       html_options.merge(class: 'span attribute_key_dropdown'))

      content << select(:filters, "attributes[#{time}][constraint]",
                        [[t('.match'), :match], [t('.equal'), :equal]],
                        { selected: (attr[:constraint] if attr) },
                        html_options.merge(class: 'span2 attribute_constraint_dropdown'))

      content << text_field_tag("filters[attributes][#{time}][value]",
                                (attr[:value] if attr),
                                html_options.merge(class: 'span2 attribute_value_input'))

      content << link_to(icon(:trash), '#',
                         class: 'remove_filter_attribute',
                         style: 'padding-left: 7px; line-height: 2em')
    end
  end
end
