# frozen_string_literal: true

#  Copyright (c) 2012-2021, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# rubocop:disable Metrics/ClassLength,Rails/HelperInstanceVariable

# A form builder that automatically selects the corresponding input field
# for ActiveRecord column types. Convenience methods for each column type allow
# one to customize the different fields.
# All field methods may be prefixed with 'labeled_' in order to render
# a standard label with them.
class StandardFormBuilder < ActionView::Helpers::FormBuilder
  include NestedForm::BuilderMixin

  REQUIRED_MARK = ' <span class="required">*</span>'.html_safe

  attr_reader :template

  delegate :association, :column_type, :column_property, :captionize, :ta, :tag,
           :content_tag, :safe_join, :capture, :add_css_class, :assoc_and_id_attr,
           :render, :f, :icon,
           to: :template

  # Render multiple input fields together with a label for the given attributes.
  def labeled_input_fields(*attrs)
    options = attrs.extract_options!
    safe_join(attrs) { |a| labeled_input_field(a, options.clone) }
  end

  # Render a corresponding input field for the given attribute.
  # The input field is chosen based on the ActiveRecord column type.
  # Use additional html_options for the input element.
  def input_field(attr, html_options = {}) # rubocop:disable Metrics/MethodLength,Metrics/CyclomaticComplexity
    type = column_type(@object, attr.to_sym)
    custom_field_method = :"#{type}_field"
    if type == :text
      text_area(attr, html_options)
    elsif association_kind?(attr, type, :belongs_to)
      belongs_to_field(attr, html_options)
    elsif association_kind?(attr, type, :has_and_belongs_to_many, :has_many)
      has_many_field(attr, html_options)
    elsif attr.to_s.include?('password')
      password_field(attr, html_options)
    elsif attr.to_s.include?('email')
      email_field(attr, html_options)
    elsif respond_to?(custom_field_method)
      send(custom_field_method, attr, html_options)
    else
      text_field(attr, html_options)
    end
  end

  # Render a password field
  def password_field(attr, html_options = {})
    html_options[:class] ||= 'span6'
    super(attr, html_options)
  end

  # Render a text_area.
  def text_area(attr, html_options = {})
    html_options[:class] ||= 'span6'
    html_options[:rows] ||= 5
    super(attr, html_options)
  end

  # Render an action text input field.
  def rich_text_area(attr, html_options = {})
    super(attr, html_options)
  end

  # Render a number field.
  def number_field(attr, html_options = {})
    html_options[:size] ||= 10
    html_options[:class] ||= 'span2'
    text_field(attr, html_options)
  end
  alias integer_field number_field
  alias float_field number_field
  alias decimal_field number_field

  # Render a standard string field with column contraints.
  def string_field(attr, html_options = {})
    html_options[:maxlength] ||= column_property(@object, attr, :limit)
    html_options[:class] ||= 'span6'
    text_field(attr, html_options)
  end

  def email_field(attr, html_options = {})
    html_options[:class] ||= 'span6'
    super(attr, html_options)
  end

  # Render a boolean field.
  def boolean_field(attr, html_options = {})
    caption   = ' ' + html_options.delete(:caption).to_s
    checked   = html_options.delete(:checked_value) { '1' }
    unchecked = html_options.delete(:unchecked_value) { '0' }

    label(attr, class: 'checkbox') do
      check_box(attr, html_options, checked, unchecked) + caption.html_safe # rubocop:disable Rails/OutputSafety
    end
  end

  # Render a field to select a date. You might want to customize this.
  def date_field(attr, html_options = {})
    html_options[:value] ||= date_value(attr)
    html_options[:class] ||= 'span2 date'
    content_tag(:div, class: 'input-prepend') do
      content_tag(:span, icon(:'calendar-alt'), class: 'add-on') +
      text_field(attr, html_options)
    end
  end

  def date_value(attr)
    raw = @object.timeliness_cache_attribute(attr)
    if raw
      raw
    else
      val = @object.send(attr)
      val.is_a?(Date) ? template.l(val) : val
    end
  end

  # Render a field to enter a time. You might want to customize this.
  def time_field(attr, html_options = {})
    html_options[:class] ||= 'time'
    time_select(attr, { include_blank: true, ignore_date: true }, html_options)
  end

  # Render a select with minutes
  def minutes_select(attr, html_options = {})
    html_options[:class] ||= 'time'
    ma = (0..59).collect { |n| [format('%02d', n), n] }
    select(attr, ma, {}, html_options)
  end

  # Render a select with hours
  def hours_select(attr, html_options = {})
    html_options[:class] ||= 'time'
    ma = (0..23).collect { |n| [format('%02d', n), n] }
    select(attr, ma, {}, html_options)
  end

  # Render a field to enter a date and time.
  # Include DatetimeAttribute in the model to use this.
  def datetime_field(attr, html_options = {})
    html_options[:class] ||= 'span6'

    date_field("#{attr}_date") +
    ' ' +
    hours_select("#{attr}_hour") +
    ' : ' +
    minutes_select("#{attr}_min")
  end

  def inline_radio_button(attr, value, caption, inline = true, html_options = {})
    label(id_from_value(attr, value), class: "radio#{' inline' if inline}") do
      radio_button(attr, value, html_options) + ' ' +
      caption
    end
  end

  # custom build tags (check_box includes "0" for every value)
  # - custom param name to allow array values without sending "0" for
  #   not selected boxes (like check_box helper)
  # - sanitized id copied from private ActionView::Helpers::FormTagHelper#sanitized_to_id
  #   (used in label_tag)
  def inline_nested_form_custom_checkbox(attr, value, index)
    name = object_name + "[#{attr}][]"
    sanitized_id = "#{object_name}_#{index}".delete(']').gsub(/[^-a-zA-Z0-9:.]/, '_')
    checked = @object.send(attr).to_s.split(', ').include?(value)
    hidden_field = index == 0 ? @template.hidden_field_tag(name, index) : ''

    @template.label_tag(sanitized_id, class: 'checkbox') do
      hidden_field.html_safe +
      @template.check_box_tag(name, index + 1, checked, id: sanitized_id) +
      ' ' +
      value
    end
  end

  def inline_check_box(attr, value, caption, html_options = {})
    model_param = klass.model_name.param_key
    name = "#{model_param}[#{attr}][]"
    id = id_from_value(attr, value)
    html_options[:id] = "#{model_param}_#{id}"
    label(id, class: 'checkbox inline') do
      @template.check_box_tag(name, value, @object.send(attr).include?(value), html_options) +
      ' ' +
      caption
    end
  end

  # Render a select element for a :belongs_to association defined by attr.
  # Use additional html_options for the select element.
  # To pass a custom element list, specify the list with the :list key or
  # define an instance variable with the pluralized name of the association.
  def belongs_to_field(attr, html_options = {})
    html_options[:class] ||= 'span6'
    list = association_entries(attr, html_options)
    if list.present?
      collection_select(attr, list, :id, :to_s,
                        collection_prompt(attr, html_options),
                        html_options)
    else
      content_tag(:p, ta(:none_available, association(@object, attr)), class: 'text')
    end
  end

  # Render a multi select element for a :has_many or :has_and_belongs_to_many
  # association defined by attr.
  # Use additional html_options for the select element.
  # To pass a custom element list, specify the list with the :list key or
  # define an instance variable with the pluralized name of the association.
  def has_many_field(attr, html_options = {}) # rubocop:disable Naming/PredicateName
    html_options[:multiple] = true
    html_options[:class] ||= 'span6'
    add_css_class(html_options, 'multiselect')
    belongs_to_field(attr, html_options)
  end

  def i18n_enum_field(attr, labels, html_options = {})
    html_options[:class] ||= 'span6'
    collection_select(attr, labels, :first, :last,
                      collection_prompt(attr, html_options),
                      html_options)
  end

  def person_field(attr, _html_options = {})
    attr, attr_id = assoc_and_id_attr(attr)
    hidden_field(attr_id) +
    string_field(attr,
                 placeholder: I18n.t('global.search.placeholder_person'),
                 data: { provide: 'entity',
                         id_field: "#{object_name}_#{attr_id}",
                         url: @template.query_people_path })
  end

  def labeled_inline_fields_for(assoc, partial_name = nil, record_object = nil, required = false,
                                &block)
    required_class = required ? ' required' : nil
    content_tag(:div, class: ['control-group', required_class].compact.join(' ')) do
      label(assoc, class: 'control-label') +
      nested_fields_for(assoc, partial_name, record_object) do |fields|
        content = block_given? ? capture(fields, &block) : render(partial_name, f: fields)

        content << help_inline(fields.link_to_remove(I18n.t('global.associations.remove')))
        content_tag(:div, content, class: 'controls controls-row well')
      end
    end
  end

  def nested_fields_for(assoc, partial_name = nil, record_object = nil, &block)
    content_tag(:div, id: "#{assoc}_fields") do
      fields_for(assoc, record_object) do |fields|
        block_given? ? capture(fields, &block) : render(partial_name, f: fields)
      end
    end +
    content_tag(:div, class: 'controls') do
      content_tag(:p, link_to_add(I18n.t('global.associations.add'), assoc), class: 'text')
    end
  end

  def readonly_value(attr, html_options = {})
    html_options[:class] ||= 'inline'
    value = html_options.delete(:value) || template.format_attr(object, attr)
    content_tag(:div, value, html_options)
  end

  def error_messages
    template.render('shared/error_messages', errors: @object.errors, object: @object)
  end

  # Render a label for the given attribute with the passed field html section.
  # The following parameters may be specified:
  #   labeled(:attr) { #content }
  #   labeled(:attr, content)
  #   labeled(:attr, 'Caption') { #content }
  #   labeled(:attr, 'Caption', content)
  def labeled(attr, caption_or_content = nil, content = nil, html_options = {}, &block) # rubocop:disable Metrics/MethodLength
    if block_given?
      content = capture(&block)
    elsif content.nil?
      content = caption_or_content
      caption_or_content = nil
    end
    caption_or_content ||= captionize(attr, klass)
    add_css_class(html_options, 'controls')
    css_classes = { 'control-group' => true,
                    error: errors_on?(attr),
                    required: required?(attr),
                    'no-attachments': no_attachments?(attr) }
    content_tag(:div, class: css_classes.select { |_css, show| show }.keys.join(' ')) do
      label(attr, caption_or_content, class: 'control-label') +
      content_tag(:div, content, html_options)
    end
  end

  def indented(content = nil, &block)
    content = capture(&block) if block_given?
    content_tag(:div, class: 'control-group') do
      content_tag(:label, '', class: 'control-label') +
      content_tag(:div, content, class: 'controls')
    end
  end

  def collection_prompt(attr, html_options = {})
    if html_options[:prompt]
      { prompt: html_options[:prompt] }
    elsif html_options[:include_blank]
      { include_blank: html_options[:include_blank] }
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
      { prompt: ta(:please_select, assoc) }
    else
      { include_blank: ta(:no_entry, assoc) }
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
      super(name, *args)
    end
  end

  # Overriden to fullfill contract with method_missing 'labeled_' methods.
  def respond_to?(name, include_all = false)
    labeled_field_method?(name).present? || super(name, include_all)
  end

  # Generates a help inline for fields
  def help_inline(text)
    content_tag(:span, text, class: 'help-inline')
  end

  # Generates a help block for fields
  def help_block(text = nil, options = {}, &block)
    additional_classes = Array(options.delete(:class))
    content_tag(:span, text, class: "help-block #{additional_classes.join(' ')}", &block)
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
    content_tag(:div, class: 'control-group hp') do
      label(name, name, class: 'control-label') +
      content_tag(:div, class: 'controls') do
        text_field(name, value: nil, placeholder: I18n.t('global.do_not_fill'))
      end
    end
  end

  def with_addon(addon, content = nil)
    content_tag(:div, class: 'input-append') do
      (block_given? ? yield : content) +
        content_tag(:span, addon, class: 'add-on')
    end
  end

  private

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

  def dynamic_required?(attr)
    return false unless @object.respond_to?(:required_attributes)

    @object.required_attributes.include?(attr.to_s)
  end

  def no_attachments?(attr)
    validators = klass.validators_on(attr)
    validators.any? { |v| v.kind == :no_attachments }
  end

  def labeled_field_method?(name)
    prefix = 'labeled_'
    if name.to_s.start_with?(prefix)
      field_method = name.to_s[prefix.size..-1]
      field_method if respond_to?(field_method)
    end
  end

  def build_labeled_field(field_method, *args)
    options = args.extract_options!
    label = options.delete(:label)
    addon = options.delete(:addon)

    labeled_args = [args.first]
    labeled_args << label if label.present?

    text = send(field_method, *(args << options))
    text = with_addon(addon, text) if addon.present?
    with_labeled_field_help(args.first, options) { |help| text << help }

    labeled_args << text
    labeled(*labeled_args)
  end

  def with_labeled_field_help(field, options)
    help = options.delete(:help)
    help_inline = options.delete(:help_inline)

    if help.present?
      yield help_inline(help_inline) if help_inline.present?
      yield help_block(help)
    else
      yield help_texts.render_field(field)
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
    "#{attr}_#{value.to_s.gsub(/\s/, '_').gsub(/[^-\w]/, '').downcase}"
  end

end

# rubocop:enable Metrics/ClassLength,Rails/HelperInstanceVariable
