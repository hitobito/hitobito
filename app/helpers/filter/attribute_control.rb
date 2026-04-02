#  Copyright (c) 2012-2024, Schweizer Blasmusikverband. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Filter::AttributeControl # rubocop:disable Rails/HelperInstanceVariable
  CONTROL_CLASSES = "form-control form-control-sm"
  SELECT_CLASSES = "form-select form-select-sm"

  delegate :select_tag, :hidden_field_tag, :text_field_tag, :options_from_collection_for_select,
    :safe_join, :link_to, :content_tag, :t, :icon,
    to: :template

  def initialize(template, attr, count, html_options = {})
    @template = template
    @attr = attr
    @count = count
    @html_options = html_options
    @time = (Time.zone.now.to_f * 1000).to_i + count
    @key = attr&.[](:key)
    @constraint = attr&.[](:constraint)
    @value = attr&.[](:value)
    @type = model_class.filter_attrs[key.to_sym][:type] if @key
  end

  def to_s
    content_tag(:div,
      class: 'filter_attribute_form d-flex align-items-center
              justify-content-between mb-2 controls controls-row') do
      attribute_key_hidden_field +
        attribute_key_field +
        attribute_constraint_field +
        attribute_value_field +
        attribute_remove_link
    end
  end

  private

  attr_reader :attr, :key, :constraint, :value, :type, :count, :template, :time, :html_options

  def all_field_types
    safe_join([
      string_field,
      integer_field,
      date_field,
      boolean_field
    ])
  end

  def attribute_key_hidden_field
    hidden_field_tag(
      "#{filter_name_prefix}[key]",
      key,
      disabled: attr.blank?,
      class: "attribute_key_hidden_field"
    )
  end

  def attribute_key_field
    content_tag(:div, class: "col") do
      select_tag(
        "#{filter_name_prefix}[key]",
        options_from_collection_for_select(keys_for_select, :last, :first, key),
        html_options.merge(
          disabled: true,
          class: "attribute_key_dropdown form-select form-select-sm"
        )
      )
    end
  end

  def keys_for_select
    model_class.filter_attrs.transform_values { |v| v[:label] }.invert.sort
  end

  def attribute_constraint_field
    content_tag(:div, class: "col") do
      select_tag(
        "#{filter_name_prefix}[constraint]",
        options_from_collection_for_select(
          constraint_options,
          :last,
          :first,
          constraint
        ),
        html_options.merge(class: "attribute_constraint_dropdown ms-3 form-select form-select-sm")
      )
    end
  end

  def constraint_options # rubocop:disable Metrics/CyclomaticComplexity, Metrics/AbcSize
    filters = filter_options(:equal, :blank)
    if type == :string || type == :text || key.blank?
      filters += filter_options(:match, :not_match)
    end
    if type == :integer || key.blank?
      filters += filter_options(:smaller, :greater)
    end
    if type == :date || key.blank?
      filters += filter_options(:before, :after)
    end
    filters
  end

  def filter_options(*options)
    options.map { |option| [t("filters.attributes.#{option}"), option] }
  end

  def attribute_value_field
    content_tag(:div, class: "col") do
      if type
        send(:"#{type}_field")
      else
        all_field_types
      end
    end
  end

  def string_field
    text_field(class: "string_field")
  end

  def integer_field
    text_field(class: "integer_field", type: "number")
  end

  def date_field
    text_field(class: "date date_field")
  end

  def text_field(options = {class: "string_field"})
    text_field_tag(
      "#{filter_name_prefix}[value]",
      value,
      control_html_options(options)
    )
  end

  def boolean_field
    boolean_options = [true, false].zip([I18n.t("global.yes"), I18n.t("global.no")])

    select_tag(
      "#{filter_name_prefix}[value]",
      options_from_collection_for_select(boolean_options, :first, :last, value),
      control_html_options(control_class: SELECT_CLASSES, class: "boolean_field")
    )
  end

  def control_html_options(options = {})
    classes = [
      options[:control_class] || CONTROL_CLASSES,
      options[:class],
      "attribute_value_input"
    ]
    classes << "invisible" if constraint == "blank"
    html_options.merge(class: classes.compact.join(" "))
  end

  def attribute_remove_link
    link_to(
      icon(:"trash-alt", filled: false),
      "#",
      class: "remove_filter_attribute col lh-lg ms-5"
    )
  end

  def filter_name_prefix = "filters[attributes][#{time}]"
end
