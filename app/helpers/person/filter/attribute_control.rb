#  Copyright (c) 2012-2024, Schweizer Blasmusikverband. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::Filter::AttributeControl
  CONTROL_CLASSES = "form-control form-control-sm"

  SELECT_CLASSES = "form-select form-select-sm"

  delegate :select_tag, :hidden_field_tag, :text_field_tag, :options_from_collection_for_select, :country_select,
    :safe_join, :link_to, :content_tag, :t, :icon,
    :people_filter_attributes_for_select, :people_filter_types_for_data_attribute, to: :template

  # rubocop:disable Rails/HelperInstanceVariable
  def initialize(template, attr, count, html_options = {})
    @template = template
    @attr = attr
    @count = count
    @html_options = html_options
    @time = (Time.zone.now.to_f * 1000).to_i + count
  end
  # rubocop:enable Rails/HelperInstanceVariable

  def to_s
    key, constraint, value = attr.to_h.symbolize_keys.slice(:key, :constraint, :value).values
    type = Person.filter_attrs[key.to_sym][:type] if key

    content_tag(:div,
      class: 'people_filter_attribute_form d-flex align-items-center
                        justify-content-between mb-2 controls controls-row') do
      content = attribute_key_hidden_field(key, time, disabled: attr.blank?)
      content << attribute_key_field(key, time, html_options)
      content << attribute_constraint_field(key, constraint, type, time, html_options)

      attribute_value_class = "#{(constraint == "blank") ? " invisible" : ""} attribute_value_input"
      content << content_tag(:div, class: "col") do
        if type
          send(:"#{type}_field", time, attribute_value_class, value, html_options)
        else
          all_field_types(time, attribute_value_class, value, html_options)
        end
      end

      content << link_to(icon(:"trash-alt", filled: false), "#",
        class: "remove_filter_attribute col-3 d-flex justify-content-end lh-lg ms-5")
    end
  end

  private

  attr_reader :attr, :count, :template, :time, :html_options

  def all_field_types(time, attribute_value_class, value, html_options)
    safe_join([
      string_field(time, attribute_value_class, value, html_options),
      country_select_field(time, attribute_value_class, value, html_options),
      integer_field(time, attribute_value_class, value, html_options),
      date_field(time, attribute_value_class, value, html_options),
      gender_select_field(time, attribute_value_class, value, html_options),
      boolean_field(time, attribute_value_class, value, html_options),
      language_select_field(time, attribute_value_class, value, html_options)
    ])
  end

  def attribute_key_hidden_field(key, time, disabled: false)
    hidden_field_tag("#{filter_name_prefix}[key]", key, disabled: disabled, class: "attribute_key_hidden_field")
  end

  def attribute_key_field(key, time, html_options)
    content_tag(:div, class: "col-3") do
      select_tag("#{filter_name_prefix}[key]",
        options_from_collection_for_select(people_filter_attributes_for_select, :last, :first, key),
        html_options.merge(disabled: true, class: "attribute_key_dropdown form-select form-select-sm"))
    end
  end

  def attribute_constraint_field(key, constraint, type, time, html_options)
    content_tag(:div, class: "col-3") do
      select_tag("#{filter_name_prefix}[constraint]",
        options_from_collection_for_select(constraint_options_for(type, key), :last, :first, constraint),
        html_options.merge(class: "attribute_constraint_dropdown ms-3 form-select form-select-sm"))
    end
  end

  def constraint_options_for(type, key)
    filters = [[t(".equal"), :equal], [t(".blank"), :blank]]
    filters += [[t(".match"), :match], [t(".not_match"), :not_match]] if type == :string || key.blank?
    filters += [[t(".smaller"), :smaller], [t(".greater"), :greater]] if type == :integer || key.blank?
    filters += [[t(".before"), :before], [t(".after"), :after]] if type == :date || key.blank?
    filters
  end

  def string_field(time, attribute_value_class, value, html_options)
    text_field_tag("#{filter_name_prefix}[value]",
      value,
      html_options.merge(class: "#{CONTROL_CLASSES} string_field #{attribute_value_class}"))
  end

  def country_select_field(time, attribute_value_class, value, html_options)
    country_select(filter_name_prefix,
      "value",
      {priority_countries: Settings.countries.prioritized, include_blank: "", selected: value&.flatten},
      html_options.merge(
        class: "form-select form-select-sm country_select_field #{attribute_value_class} w-100",
        "data-controller": "form-select",
        multiple: true
      ))
  end

  def integer_field(time, attribute_value_class, value, html_options)
    text_field_tag("#{filter_name_prefix}[value]",
      value,
      html_options.merge(class: "#{CONTROL_CLASSES} integer_field #{attribute_value_class}", type: "number"))
  end

  def date_field(time, attribute_value_class, value, html_options)
    text_field_tag("#{filter_name_prefix}[value]",
      value,
      html_options.merge(class: "#{CONTROL_CLASSES} date date_field #{attribute_value_class}"))
  end

  def gender_select_field(time, attribute_value_class, value, html_options)
    gender_options = (Person::GENDERS + [""]).collect { |g| [g, Person.new.gender_label(g)] }
    select_tag("#{filter_name_prefix}[value]",
      options_from_collection_for_select(gender_options, :first, :last, value),
      html_options.merge(class: "#{SELECT_CLASSES} gender_select_field #{attribute_value_class}"))
  end

  def boolean_field(time, attribute_value_class, value, html_options)
    boolean_options = [true, false].zip([I18n.t("global.yes"), I18n.t("global.no")])

    select_tag("#{filter_name_prefix}[value]",
      options_from_collection_for_select(boolean_options, :first, :last, value),
      html_options.merge(class: "#{SELECT_CLASSES} boolean_field #{attribute_value_class}"))
  end

  def language_select_field(time, attribute_value_class, value, html_options)
    language_options = Person::LANGUAGES.collect { |language_value, language_name| [language_name, language_value] }
    select_tag("#{filter_name_prefix}[value]",
      options_from_collection_for_select(language_options, :second, :first, value&.flatten&.map(&:to_sym)),
      html_options.merge(
        class: "#{SELECT_CLASSES} language_select_field #{attribute_value_class} form-select form-select-sm w-100",
        multiple: true,
        id: "language-select-#{time}",
        "data-controller": "form-select"
      ))
  end

  def filter_name_prefix = "filters[attributes][#{time}]"
end
