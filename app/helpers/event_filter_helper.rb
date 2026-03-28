#  Copyright (c) 2026, Schweizer Alpenclub SAC. This file is part of
#  hitobito_sbv and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sbv.

module EventFilterHelper
  def event_filter_attributes_for_select(event_type = Event)
    event_type.filter_attrs.transform_values { |v| v[:label] }.invert.sort
  end

  def event_filter_types_for_data_attribute(event_type = Event)
    event_type.filter_attrs.transform_values { |v| v[:type] }.to_h.to_json
  end

  def event_filter_attribute_controls(event_type, filter)
    return unless filter

    filter.args.each_with_index.map do |(_k, attr), i|
      event_filter_attribute_control(event_type, attr, i)
    end.join.html_safe
  end

  def event_filter_attribute_control_template(event_type)
    event_filter_attribute_control(event_type, nil, 0, disabled: :disabled)
  end

  private

  def event_filter_attribute_control(event_type, attr, count, html_options = {})
    Event::Filter::AttributeControl.new(self, event_type, attr, count, html_options).to_s
  end
end
