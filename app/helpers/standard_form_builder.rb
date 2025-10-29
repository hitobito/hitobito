# frozen_string_literal: true

#  Copyright (c) 2012-2024, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# rubocop:disable Metrics/ClassLength

# A form builder that automatically selects the corresponding input field
# for ActiveRecord column types. Convenience methods for each column type allow
# one to customize the different fields.
# All field methods may be prefixed with 'labeled_' in order to render
# a standard label with them.
class StandardFormBuilder < ActionView::Helpers::FormBuilder
  include NestedForm::BuilderMixin

  REQUIRED_MARK = ' <span class="required">*</span>'.html_safe
  WIDTH_CLASSES = "mw-100 mw-md-60ch"
  FORM_CONTROL = "form-control form-control-sm"
  FORM_CONTROL_WITH_WIDTH = "form-control form-control-sm #{WIDTH_CLASSES}"
  FORM_CONTROL_SELECT_WITH_WIDTH = "form-select form-select-sm #{WIDTH_CLASSES}"
  LABEL_CLASSES = "col-md-3 col-xl-2 pb-1"

  attr_reader :template

  delegate :association, :column_type, :column_property, :captionize, :ta, :tag,
    :content_tag, :safe_join, :capture, :add_css_class, :assoc_and_id_attr,
    :render, :f, :icon, :check_box_tag, :action_button,
    to: :template

  # Render multiple input fields together with a label for the given attributes.
  def labeled_input_fields(*attrs)
    options = attrs.extract_options!
    safe_join(attrs) { |a| labeled_input_field(a, options.clone) }
  end

  # Render a corresponding input field for the given attribute.
  # The input field is chosen based on the ActiveRecord column type.
  # Use additional html_options for the input element.
  def input_field(attr, html_options = {}) # rubocop:disable Metrics/*
    type = column_type(@object, attr.to_sym)
    custom_field_method = :"#{type}_field"

    if type == :text
      text_area(attr, html_options)
    elsif association_kind?(attr, type, :belongs_to)
      belongs_to_field(attr, html_options)
    elsif association_kind?(attr, type, :has_and_belongs_to_many, :has_many)
      has_many_field(attr, html_options)
    elsif attr.to_s.include?("password")
      password_field(attr, html_options)
    elsif attr.to_s.include?("email")
      email_field(attr, html_options)
    elsif respond_to?(custom_field_method)
      send(custom_field_method, attr, html_options)
    else
      add_css_class(html_options, FORM_CONTROL_WITH_WIDTH)
      add_css_class(html_options, "is-invalid") if errors_on?(attr)
      text_field(attr, html_options)
    end
  end

  # Render a password field
  def password_field(attr, html_options = {})
    add_css_class(html_options, FORM_CONTROL_WITH_WIDTH)
    add_css_class(html_options, "is-invalid") if errors_on?(attr)
    super
  end

  # Render a text_area.
  def text_area(attr, html_options = {})
    add_css_class(html_options, FORM_CONTROL_WITH_WIDTH)
    add_css_class(html_options, "is-invalid") if errors_on?(attr)
    html_options[:rows] ||= 5
    super
  end

  # Render an action text input field.
  def rich_text_area(attr, html_options = {})
    add_css_class(html_options, FORM_CONTROL)
    add_css_class(html_options, "is-invalid") if errors_on?(attr)
    super
  end

  # Render a number field.
  def number_field(attr, html_options = {})
    html_options[:size] ||= 10
    add_css_class(html_options, "mw-100 mw-md-15ch #{FORM_CONTROL}")
    add_css_class(html_options, "is-invalid") if errors_on?(attr)
    text_field(attr, html_options)
  end
  alias_method :integer_field, :number_field
  alias_method :float_field, :number_field
  alias_method :decimal_field, :number_field

  # Render a standard string field with column contraints.
  def string_field(attr, html_options = {})
    html_options[:maxlength] ||= column_property(@object, attr, :limit)
    add_css_class(html_options, FORM_CONTROL_WITH_WIDTH)
    add_css_class(html_options, "is-invalid") if errors_on?(attr)
    text_field(attr, html_options)
  end

  def email_field(attr, html_options = {})
    add_css_class(html_options, FORM_CONTROL_WITH_WIDTH)
    add_css_class(html_options, "is-invalid") if errors_on?(attr)
    super
  end

  def file_field(attr, html_options = {})
    add_css_class(html_options, "is-invalid") if errors_on?(attr)
    super
  end

  # Render a boolean field.
  def boolean_field(attr, html_options = {}) # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
    caption = " "
    caption += if html_options[:required]
      content_tag(:span, class: "required-asterisk") do
        html_options.delete(:caption).to_s
      end
    else
      html_options.delete(:caption).to_s
    end
    checked = html_options.delete(:checked_value) { "1" }
    unchecked = html_options.delete(:unchecked_value) { "0" }
    add_css_class(html_options, "form-check-input")
    add_css_class(html_options, "is-invalid") if errors_on?(attr)

    content_tag(:div, class: "form-check") do
      check_box(attr, html_options, checked, unchecked) +
        label(attr, caption.html_safe, class: "form-check-label me-2")
    end
  end

  # Render a field to select a date. You might want to customize this.
  def date_field(attr, html_options = {})
    html_options[:value] ||= date_value(attr)
    html_options[:autocomplete] ||= "off"
    add_css_class(html_options, "mw-100 mw-md-20ch date #{FORM_CONTROL}")
    add_css_class(html_options, "is-invalid") if errors_on?(attr)
    content_tag(:div, class: "input-group") do
      content_tag(:span, icon(:"calendar-alt"), class: "input-group-text") +
        text_field(attr, html_options)
    end
  end

  # Render a select dropdown for countries
  def country_field(attr = :country, **html_options)
    add_css_class(html_options, "form-select form-select-sm")
    add_css_class(html_options, "is-invalid") if errors_on?(attr)
    html_options[:data] = {
      placeholder: " ",
      chosen_no_results: I18n.t("global.chosen_no_results"),
      controller: "tom-select"
    }

    country_select(attr,
      {priority_countries: Settings.countries.prioritized,
       selected: @object.send(attr),
       include_blank: ""},
      html_options)
  end

  def date_value(attr)
    # Can also be serialized column
    raw = @object.timeliness_cache_attribute(attr) if @object.is_a?(ActiveRecord::Base)
    if raw
      raw
    else
      val = @object.send(attr)
      val.is_a?(Date) ? template.l(val) : val
    end
  end

  # Render a field to enter a time. You might want to customize this.
  def time_field(attr, html_options = {})
    html_options[:class] ||= "time"
    add_css_class(html_options, "is-invalid") if errors_on?(attr)
    time_select(attr, {include_blank: "", ignore_date: true}, html_options)
  end

  # Render a select with minutes
  def minutes_select(attr, html_options = {})
    html_options[:class] ||= "time form-select form-select-sm"
    add_css_class(html_options, "is-invalid") if errors_on?(attr)
    ma = (0..59).collect { |n| [format("%02d", n), n] }
    select(attr, ma, {}, html_options)
  end

  # Render a select with hours
  def hours_select(attr, html_options = {})
    html_options[:class] ||= "time form-select form-select-sm"
    add_css_class(html_options, "is-invalid") if errors_on?(attr)
    ma = (0..23).collect { |n| [format("%02d", n), n] }
    select(attr, ma, {}, html_options)
  end

  # Render a field to enter a date and time.
  # Include DatetimeAttribute in the model to use this.
  def datetime_field(attr, html_options = {})
    add_css_class(html_options, FORM_CONTROL_WITH_WIDTH)
    add_css_class(html_options, "is-invalid") if errors_on?(attr)

    content_tag(:div, class: "d-flex align-items-center") do
      content_tag(:div, class: 'col-7 col-md-7
                                col-lg-5 me-1') { date_field("#{attr}_date") } +
        hours_select("#{attr}_hour") +
        content_tag(:div) { ":" } +
        minutes_select("#{attr}_min")
    end
  end

  def inline_radio_button(attr, value, caption, inline = true, html_options = {})
    add_css_class(html_options, "form-check-input")
    add_css_class(html_options, "is-invalid") if errors_on?(attr)
    invalid = errors_on?(attr) ? " is-invalid" : ""
    id = id_from_value(attr, value)

    content_tag(:div, class: "form-check#{inline ? " form-check-inline " : ""}") do
      radio_button(attr, value, html_options) +
        label(id, caption, class: "form-check-label" + invalid)
    end
  end

  def inline_check_box(attr, value, caption, html_options = {}) # rubocop:disable Metrics/MethodLength
    add_css_class(html_options, "form-check-input")
    add_css_class(html_options, "is-invalid") if errors_on?(attr)
    invalid = errors_on?(attr) ? " is-invalid" : ""
    model_param = klass.model_name.param_key
    name = "#{model_param}[#{attr}][]"
    id = id_from_value(attr, value)
    checked = @object.send(attr).include?(value)
    html_options[:id] = "#{model_param}_#{id}"

    content_tag(:div, class: "form-check form-check-inline") do
      check_box_tag(name, value, checked, html_options) +
        label(id, caption, class: "form-check-label" + invalid)
    end
  end

  # Render a select element for a :belongs_to association defined by attr.
  # Use additional html_options for the select element.
  # To pass a custom element list, specify the list with the :list key or
  # define an instance variable with the pluralized name of the association.
  def belongs_to_field(attr, html_options = {})
    add_css_class(html_options, FORM_CONTROL_SELECT_WITH_WIDTH)
    add_css_class(html_options, "is-invalid") if errors_on?(attr)
    list = association_entries(attr, html_options)
    if list.present?
      collection_select(attr, list, :id, :to_s, collection_prompt(attr, html_options), html_options)
    else
      content_tag(:p, ta(:none_available, association(@object, attr)), class: "text")
    end
  end

  # Render a multi select element for a :has_many or :has_and_belongs_to_many
  # association defined by attr.
  # Use additional html_options for the select element.
  # To pass a custom element list, specify the list with the :list key or
  # define an instance variable with the pluralized name of the association.
  def has_many_field(attr, html_options = {}) # rubocop:disable Naming/PredicateName
    html_options[:multiple] = true
    add_css_class(html_options, FORM_CONTROL_SELECT_WITH_WIDTH)
    add_css_class(html_options, "is-invalid") if errors_on?(attr)
    html_options[:data].to_h.merge!(
      chosen_no_results: I18n.t("global.chosen_no_results"),
      placeholder: " ",
      controller: "tom-select"
    )

    add_css_class(html_options, "multiselect")
    belongs_to_field(attr, html_options)
  end

  def i18n_enum_field(attr, labels, html_options = {})
    add_css_class(html_options, FORM_CONTROL_SELECT_WITH_WIDTH)
    add_css_class(html_options, "is-invalid") if errors_on?(attr)
    collection_select(attr, labels, :first, :last,
      collection_prompt(attr, html_options),
      html_options)
  end

  def person_field(attr, html_options = {}) # rubocop:disable Metrics/MethodLength
    attr, attr_id = assoc_and_id_attr(attr)
    add_css_class(html_options, FORM_CONTROL_WITH_WIDTH)
    add_css_class(html_options, "is-invalid") if errors_on?(attr)
    disabled = html_options[:disabled].presence
    hidden_field(attr_id) +
      string_field(attr,
        placeholder: I18n.t("global.search.placeholder_person"),
        class: html_options[:class],
        disabled: disabled,
        data: html_options[:data].to_h.merge!(
          provide: "entity",
          id_field: "#{object_name}_#{attr_id}",
          no_results_message: I18n.t("global.no_list_entries"),
          url: html_options.dig(:data, :url) || @template.query_people_path
        ))
  end

  def labeled_inline_fields_for(assoc, partial = nil, record = nil, required = false, &block) # rubocop:disable Metrics/MethodLength
    html_options = {class: "labeled controls mb-3 mt-1 d-flex " \
                            "justify-content-start align-items-baseline"}
    css_classes = {row: true, "mb-2": true, required: required}
    label_classes = "control-label col-form-label col-md-3 col-xl-2 pb-1 text-md-end"
    label_classes += " required" if required
    content_tag(:div, class: css_classes.select { |_css, show| show }.keys.join(" ")) do
      label(assoc, class: label_classes) +
        content_tag(:div, class: "labeled col-md") do
          nested_fields_for(assoc, partial, record) do |fields|
            content = block ? capture(fields, &block) : render(partial, f: fields)
            content = content_tag(:div, content, class: "col-md-10")

            content << content_tag(:div, fields.link_to_remove(icon(:times)), class: "col-md-2")
            content_tag(:div, content, html_options)
          end
        end
    end
  end

  def nested_fields_for(assoc, partial_name = nil, record_object = nil, options = nil, limit = nil,
    &block)
    content_tag(:div, id: "#{assoc}_fields", data: {association: assoc, limit: limit}) do
      fields_for(assoc, record_object) do |fields|
        block ? capture(fields, &block) : render(partial_name, f: fields)
      end
    end +
      content_tag(:div, class: "controls") do
        options = options.to_h.merge(class: "text w-100 align-with-form")
        link_title = options.delete(:link_to_add_title) || I18n.t("global.associations.add")
        content_tag(:p, link_to_add(link_title, assoc, options))
      end
  end

  def readonly_value(attr, html_options = {})
    html_options[:class] ||= "mt-2"
    value = html_options.delete(:value) || template.format_attr(object, attr)
    content_tag(:div, value, html_options)
  end

  def error_messages
    template.render("shared/error_messages", errors: @object.errors, object: @object)
  end

  # Render a label for the given attribute with the passed field html section.
  # The following parameters may be specified:
  #   labeled(:attr) { #content }
  #   labeled(:attr, content)
  #   labeled(:attr, 'Caption') { #content }
  #   labeled(:attr, 'Caption', content)
  # rubocop:todo Layout/LineLength
  def labeled(attr, caption_or_content = nil, content = nil, mark_as_required: false, **html_options, &block) # rubocop:disable Metrics/*
    # rubocop:enable Layout/LineLength
    if block
      content = capture(&block)
    elsif content.nil?
      content = caption_or_content
      caption_or_content = nil
    end
    caption_or_content ||= captionize(attr, klass)

    label_classes = html_options.delete(:label_class) || "col-md-3 col-xl-2 pb-1"
    label_classes += " col-form-label text-md-end"
    label_classes += " required" if mark_as_required || required?(attr)

    add_css_class(html_options, "labeled col-md-9 col-lg-8 col-xl-8 mw-63ch")
    css_classes = {"no-attachments": no_attachments?(attr),
                   row: true, "mb-2": true}

    content_tag(:div, class: css_classes.select { |_css, show| show }.keys.join(" ")) do
      label(attr, caption_or_content, class: label_classes) +
        content_tag(:div, content, html_options)
    end
  end

  def indented(content = nil, &block)
    content = capture(&block) if block
    content_tag(:div, class: "row mb-2") do
      content_tag(:div, content, class: "offset-md-3 offset-xl-2")
    end
  end

  def collection_prompt(attr, html_options = {})
    if html_options[:prompt]
      {prompt: html_options[:prompt]}
    elsif html_options[:include_blank]
      {include_blank: html_options[:include_blank]}
    elsif html_options[:multiple]
      {}
    else
      select_options(attr)
    end
  end

  # Depending if the given attribute must be present, return
  # only an initial selection prompt or a blank option, respectively.
  def select_options(attr)
    assoc = association(@object, attr)
    if required?(attr)
      {prompt: ta(:please_select, assoc)}
    else
      {include_blank: ta(:no_entry, assoc)}
    end
  end

  # Dispatch methods starting with 'labeled_' to render a label and the corresponding
  # input field. E.g. labeled_boolean_field(:checked, :class => 'bold')
  # To add an additional help text, use the help option.
  # E.g. labeled_boolean_field(:checked, :help => 'Some Help')
  def method_missing(name, *args)
    field_method = labeled_field_method?(name)
    if field_method
      build_labeled_field(field_method, *args)
    else
      super
    end
  end

  # Overriden to fullfill contract with method_missing 'labeled_' methods.
  def respond_to_missing?(name, include_all = false)
    labeled_field_method?(name).present? || super
  end

  # Generates a help inline for fields
  def help_inline(text)
    content_tag(:span, "", class: "d-block") +
      content_tag(:span, text, class: "form-text d-block")
  end

  # Generates a help block for fields
  def help_block(text = nil, options = {}, &block)
    additional_classes = Array(options.delete(:class))
    content_tag(:div, text, class: "form-text #{additional_classes.join(" ")}", &block)
  end

  # Returns the list of association entries, either from options[:list],
  # the instance variable with the pluralized association name or all
  # entries of the association klass.
  def association_entries(attr, options = {})
    list = options.delete(:list)
    unless list
      assoc = association(@object, attr)
      list = @template.send(:instance_variable_get, :"@#{assoc.name.to_s.pluralize}")
      list ||= assoc.klass.where(assoc.options[:conditions]).order(assoc.options[:order])
    end
    list
  end

  def honeypot(name = :name)
    content_tag(:div, class: "control-group hp") do
      label(name, name, class: "control-label") +
        content_tag(:div, class: "controls") do
          text_field(name, value: nil, placeholder: I18n.t("global.do_not_fill"))
        end
    end
  end

  def with_addon(addon, content = nil)
    content_tag(:div, class: "input-group input-group-sm") do
      (block_given? ? yield : content) +
        content_tag(:span, addon, class: "input-group-text")
    end
  end

  def translated_input_field(attr, args = {})
    content_tag(:div, "data-controller": "translatable-fields") do
      input_for_locale_with_translation_button(attr, I18n.locale, **args, value: @object.send(:"#{attr}_#{I18n.locale}")) +
        content_tag(:div, {class: "hidden", "data-translatable-fields-target": "toggle"}) do
          other_lang_inputs = I18n.available_locales.excluding(I18n.locale).map do |locale|
            input_for_locale("#{attr}_#{locale}", locale, **args, data: {
              "translatable-fields-target": "translatedField",
              action: "input->translatable-fields#updateTranslatedFields trix-change->translatable-fields#updateTranslatedFields"
            })
          end
          safe_join(other_lang_inputs)
        end
    end
  end

  private

  def input_for_locale_with_translation_button(attr, locale, args = {})
    content_tag(:div, class: "d-flex") do
      input_for_locale(attr, locale, args) +
        action_button(nil, nil, "language", {class: "mb-2", "data-action": "translatable-fields#toggleFields", type: "button", in_button_group: true})
    end
  end

  def input_for_locale(attr, locale, args = {})
    args = args.dup
    rich_text = args.delete(:rich_text) || false
    content_tag(:div, class: "input-group me-2 mb-2") do
      input_for_locale = content_tag(:span, locale.to_s.upcase, class: "input-group-text") +
        (rich_text ? rich_text_area(attr, **args) : input_field(attr, **args))
      input_for_locale += content_tag(:span, "-", class: "input-group-text", "data-translatable-fields-target": "translatedFieldsDisplay") if locale == I18n.locale
      input_for_locale
    end
  end

  # Returns true if attr is a non-polymorphic association.
  # If one or more macros are given, the association must be of this kind.
  def association_kind?(attr, type, *macros)
    if type == :integer || type.nil?
      assoc = association(@object, attr, *macros)
      assoc.present? && assoc.options[:polymorphic].nil?
    else
      false
    end
  end

  def errors_on?(attr)
    return false if @object.errors.blank?

    attr_plain, attr_id = assoc_and_id_attr(attr)
    @object.errors.key?(attr_plain.to_sym) ||
      @object.errors.key?(attr_id.to_sym)
  end

  # Returns true if the given attribute must be present.
  def required?(attr)
    return true if dynamic_required?(attr)

    attr = attr.to_s
    attr, attr_id = assoc_and_id_attr(attr)
    validators = klass.validators_on(attr) +
      klass.validators_on(attr_id)
    validators.any? do |v|
      v.kind == :presence &&
        !v.options.key?(:if) && !v.options.key?(:unless)
    end
  end

  # required_attrs are dynamically defined attributes, that also get checked during validation
  # if the form label should just display the required mark, without adding a validation e.g.
  # for nested fields with a seperate label, mark_as_required? can be defined on the model
  def dynamic_required?(attr)
    return true if @object.respond_to?(:mark_as_required?) && @object.mark_as_required?(attr)
    return false unless @object.respond_to?(:required_attrs)

    @object.required_attrs.include?(attr)
  end

  def no_attachments?(attr)
    return false unless @object

    validators = klass.validators_on(attr)
    validators.any? { |v| v.kind == :no_attachments }
  end

  def labeled_field_method?(name)
    prefix = "labeled_"
    if name.to_s.start_with?(prefix)
      field_method = name.to_s[prefix.size..]
      field_method if respond_to?(field_method)
    end
  end

  def build_labeled_field(field_method, *args) # rubocop:disable Metrics/MethodLength
    options = args.extract_options!
    label = options.delete(:label)
    label_class = options.delete(:label_class)
    addon = options.delete(:addon)
    help = options.delete(:help)
    help_inline = options.delete(:help_inline)

    attr = args.first
    caption = label if label.present?

    content = send(field_method, *(args << options))
    content = with_addon(addon, content) if addon.present?
    with_labeled_field_help(attr, help, help_inline) { |element| content << element }

    labeled(attr, caption, content, required: options[:required], label_class: label_class)
  end

  def with_labeled_field_help(attr, help, help_inline)
    if help.present?
      yield help_inline(help_inline) if help_inline.present?
      yield help_block(help)
    else
      yield help_texts.render_field(attr)
      yield help_inline(help_inline) if help_inline.present?
    end
  end

  def help_texts
    @help_texts ||= HelpTexts::Renderer.new(template)
  end

  def klass
    @klass ||= @object.respond_to?(:klass) ? @object.klass : @object.class
  end

  def id_from_value(attr, value)
    "#{attr}_#{value.to_s.gsub(/\s/, "_").gsub(/[^-\w]/, "").downcase}"
  end
end

# rubocop:enable Metrics/ClassLength
