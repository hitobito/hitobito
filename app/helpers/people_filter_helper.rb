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

  def people_filter_attribute_control_template
    people_filter_attribute_control(nil, 0, disabled: :disabled)
  end

  private

  def people_filter_attribute_control(attr, count, html_options = {})
    Person::Filter::AttributeControl.new(self, attr, count, html_options).to_s
  end
end
