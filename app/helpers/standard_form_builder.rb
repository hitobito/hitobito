# encoding: utf-8
# A form builder that automatically selects the corresponding input field
# for ActiveRecord column types. Convenience methods for each column type allow
# one to customize the different fields.
# All field methods may be prefixed with 'labeled_' in order to render
# a standard label with them.
class StandardFormBuilder < ActionView::Helpers::FormBuilder
  include NestedForm::BuilderMixin

  REQUIRED_MARK = '<span class="required">*</span>'.html_safe

  attr_reader :template

  delegate :association, :column_type, :column_property, :captionize, :ta, :tag,
           :content_tag, :safe_join, :capture, :add_css_class, :assoc_and_id_attr,
           :render, 
           :to => :template

  # Render multiple input fields together with a label for the given attributes.
  def labeled_input_fields(*attrs)
    options = attrs.extract_options!
    safe_join(attrs) { |a| labeled_input_field(a, options.clone) }
  end

  # Render a corresponding input field for the given attribute.
  # The input field is chosen based on the ActiveRecord column type.
  # Use additional html_options for the input element.
  def input_field(attr, html_options = {})
    type = column_type(@object, attr)
    if type == :text
      text_area(attr, html_options)
    elsif association_kind?(attr, type, :belongs_to)
      belongs_to_field(attr, html_options)
    elsif association_kind?(attr, type, :has_and_belongs_to_many, :has_many)
      has_many_field(attr, html_options)
    elsif attr.to_s.include?('password')
      password_field(attr, html_options)
    else
      custom_field_method = :"#{type}_field"
      if respond_to?(custom_field_method)
        send(custom_field_method, attr, html_options)
      else
        text_field(attr, html_options)
      end
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

  # Render a number field.
  def number_field(attr, html_options = {})
    html_options[:size] ||= 10
    html_options[:class] ||= 'span6'
    super(attr, html_options)
  end

  # Render a standard string field with column contraints.
  def string_field(attr, html_options = {})
    html_options[:maxlength] ||= column_property(@object, attr, :limit)
    html_options[:class] ||= 'span6'
    text_field(attr, html_options)
  end

  # Render an integer field.
  def integer_field(attr, html_options = {})
    html_options[:step] ||= 1
    html_options[:class] ||= 'span6'
    number_field(attr, html_options)
  end

  # Render a float field.
  def float_field(attr, html_options = {})
    html_options[:step] ||= 'any'
    html_options[:class] ||= 'span6'
    number_field(attr, html_options)
  end

  # Render a decimal field.
  def decimal_field(attr, html_options = {})
    html_options[:step] ||= 'any'
    number_field(attr, html_options)
  end

  # Render a boolean field.
  def boolean_field(attr, html_options = {})
    check_box(attr, html_options)
  end

  # Render a field to select a date. You might want to customize this.
  def date_field(attr, html_options = {})
    html_options[:class] ||= 'span6'
    date_select(attr, {}, html_options)
  end

  # Render a field to enter a time. You might want to customize this.
  def time_field(attr, html_options = {})
    html_options[:class] ||= 'span6'
    time_select(attr, {}, html_options)
  end

  # Render a field to enter a date and time. You might want to customize this.
  def datetime_field(attr, html_options = {})
    html_options[:class] ||= 'span6'
    datetime_select(attr, {}, html_options)
  end

  # Render a select element for a :belongs_to association defined by attr.
  # Use additional html_options for the select element.
  # To pass a custom element list, specify the list with the :list key or
  # define an instance variable with the pluralized name of the association.
  def belongs_to_field(attr, html_options = {})
    html_options[:class] ||= 'span6'
    list = association_entries(attr, html_options)
    if list.present?
      collection_select(attr,
                        list,
                        :id,
                        :to_s,
                        html_options[:multiple] ? {} : select_options(attr),
                        html_options)
    else
      ta(:none_available, association(@object, attr))
    end
  end

  # Render a multi select element for a :has_many or :has_and_belongs_to_many
  # association defined by attr.
  # Use additional html_options for the select element.
  # To pass a custom element list, specify the list with the :list key or
  # define an instance variable with the pluralized name of the association.
  def has_many_field(attr, html_options = {})
    html_options[:multiple] = true
    html_options[:class] ||= 'span6'
    add_css_class(html_options, 'multiselect')
    belongs_to_field(attr, html_options)
  end


  def inline_fields_for(assoc,partial_name=nil, &block) 
    content_tag(:div, class: 'control-group') do
      label(assoc, class: 'control-label') +
      content_tag(:div, id: "#{assoc}_fields") do
        fields_for(assoc) do |fields|
          content = block_given? ? capture(fields, &block) : render(partial_name, f: fields)
          content << fields.link_to_remove('Entfernen')
          content_tag(:div, content, class: 'controls controls-row') 
        end 
      end + 
      content_tag(:div, class: 'controls') do
        link_to_add 'Eintrag hinzufügen', assoc
      end
    end
  end

  # Renders a marker if the given attr has to be present.
  def required_mark(attr)
    required?(attr) ? REQUIRED_MARK : ''
  end

  # Render a label for the given attribute with the passed field html section.
  # The following parameters may be specified:
  #   labeled(:attr) { #content }
  #   labeled(:attr, content)
  #   labeled(:attr, 'Caption') { #content }
  #   labeled(:attr, 'Caption', content)
  def labeled(attr, caption_or_content = nil, content = nil, html_options = {}, &block)
    if block_given?
      content = capture(&block)
    elsif content.nil?
      content = caption_or_content
      caption_or_content = nil
    end
    caption_or_content ||= captionize(attr, @object.class)
    add_css_class(html_options, 'controls')

    content_tag(:div, :class => "control-group#{' error' if @object.errors.has_key?(attr)}") do
      label(attr, caption_or_content, :class => 'control-label') +
      content_tag(:div, content, html_options)
    end
  end
  
  def indented(content = nil, &block)
    content = capture(&block) if block_given?
    content_tag(:div, :class => "control-group") do
      content_tag(:label, '', :class => 'control-label') +
      content_tag(:div, content, :class => 'controls')
    end
  end

  # Depending if the given attribute must be present, return
  # only an initial selection prompt or a blank option, respectively.
  def select_options(attr)
    assoc = association(@object, attr)
    required?(attr) ? { :prompt => ta(:please_select, assoc) } :
                      { :include_blank => ta(:no_entry, assoc) }
  end

  # Dispatch methods starting with 'labeled_' to render a label and the corresponding
  # input field. E.g. labeled_boolean_field(:checked, :class => 'bold')
  # To add an additional help text, use the help option.
  # E.g. labeled_boolean_field(:checked, :help => 'Some Help')
  def method_missing(name, *args)
    if field_method = labeled_field_method?(name)
      build_labeled_field(field_method, *args)
    else
      super(name, *args)
    end
  end

  # Overriden to fullfill contract with method_missing 'labeled_' methods.
  def respond_to?(name)
    labeled_field_method?(name).present? || super(name)
  end

  # Generates a help block for fields
  def help_block(text)
    content_tag(:p, text, :class => 'help-block')
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

  # Returns the list of association entries, either from options[:list],
  # the instance variable with the pluralized association name or all
  # entries of the association klass.
  def association_entries(attr, options)
    list = options.delete(:list)
    unless list
      assoc = association(@object, attr)
      list = @template.send(:instance_variable_get, :"@#{assoc.name.to_s.pluralize}")
      unless list
        list = assoc.klass.where(assoc.options[:conditions]).order(assoc.options[:order])
      end
    end
    list
  end

  # Returns true if the given attribute must be present.
  def required?(attr)
    attr = attr.to_s
    attr, attr_id = assoc_and_id_attr(attr)
    validators = @object.class.validators_on(attr) +
                 @object.class.validators_on(attr_id)
    validators.any? do |v|
      v.kind == :presence &&
      !v.options.key?(:if) && !v.options.key?(:unless)
    end
  end

  private

  def labeled_field_method?(name)
    prefix = 'labeled_'
    if name.to_s.start_with?(prefix)
      field_method = name.to_s[prefix.size..-1]
      field_method if respond_to?(field_method)
    end
  end

 def build_labeled_field(field_method, *args)
    options = args.extract_options!
    help = options.delete(:help)
    text = send(field_method, *(args<<options)) + required_mark(args.first)
    text << help_block(help) if help.present?
    labeled(args.first, text)
  end

end
