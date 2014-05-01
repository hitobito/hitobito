# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# A view helper to standartize often used functions like formatting,
# tables, forms or action links. This helper is ideally defined in the
# ApplicationController.
module StandardHelper

  EMPTY_STRING = '&nbsp;'.html_safe   # non-breaking space asserts better css styling.

  ################  FORMATTING HELPERS  ##################################

  # Formats a single value
  def f(value)
    case value
    when Float, BigDecimal then
      number_with_precision(value,
                            precision: t('number.format.precision'),
                            delimiter: t('number.format.delimiter'))
    when Date   then l(value)
    when Time   then l(value, format: :time)
    when true   then t(:"global.yes")
    when false  then t(:"global.no")
    when nil    then EMPTY_STRING
    else value.to_s
    end
  end

  # Formats an arbitrary attribute of the given ActiveRecord object.
  # If no specific format_{type}_{attr} or format_{attr} method is found,
  # formats the value as follows:
  # If the value is an associated model, renders the label of this object.
  # Otherwise, calls format_type.
  def format_attr(obj, attr)
    format_type_attr_method = format_type_attr_method(obj, attr)
    format_attr_method = :"format_#{attr.to_s}"
    if respond_to?(format_type_attr_method)
      send(format_type_attr_method, obj)
    elsif respond_to?(format_attr_method)
      send(format_attr_method, obj)
    elsif assoc = association(obj, attr, :belongs_to)
      format_assoc(obj, assoc)
    elsif assoc = association(obj, attr, :has_many, :has_and_belongs_to_many)
      format_many_assoc(obj, assoc)
    else
      format_type(obj, attr)
    end
  end

  def format_type_attr_method(obj, attr)
    if obj.class.respond_to?(:base_class)
      "format_#{obj.class.base_class.name.underscore}_#{attr}"
    else
      "format_#{obj.class.name.underscore}_#{attr}"
    end.gsub(/\//, '_')  # deal with nested models
  end


  ##############  STANDARD HTML SECTIONS  ############################


  # Renders an arbitrary content with the given label. Used for uniform presentation.
  def labeled(label, content = nil, &block)
    content = capture(&block) if block_given?
    render 'shared/labeled', label: label, content: content
  end

  # Transform the given text into a form as used by labels or table headers.
  def captionize(text, clazz = nil)
    text = text.to_s
    if clazz.respond_to?(:human_attribute_name)
      clazz.human_attribute_name(text.end_with?('_ids') ? text[0..-5].pluralize : text)
    else
      text.humanize.titleize
    end
  end

  # Renders a list of attributes with label and value for a given object.
  # If the optional block returns false for a given attribute, it will not be rendered.
  def render_attrs(obj, *attrs)
    content_tag(:dl, class: 'dl-horizontal') do
      safe_join(attrs) do |a|
        labeled_attr(obj, a) if !block_given? || yield(a)
      end
    end if attrs.present?
  end

  # Like #render_attrs, but only for attributes with a present value.
  def render_present_attrs(obj, *attrs)
    render_attrs(obj, *attrs) do |a|
      obj.send(a).present?
    end
  end

  # Renders the formatted content of the given attribute with a label.
  def labeled_attr(obj, attr)
    labeled(captionize(attr, object_class(obj)), format_attr(obj, attr))
  end

  # Renders a table for the given entries. One column is rendered for each attribute passed.
  # If a block is given, the columns defined therein are appended to the attribute columns.
  # If entries is empty, an appropriate message is rendered.
  # An options hash may be given as the last argument.
  def table(entries, *attrs)
    entries.to_a # force evaluation of relation
    if entries.present?
      content_tag(:div, class: 'table-responsive') do
        StandardTableBuilder.table(entries, self, attrs.extract_options!) do |t|
          t.attrs(*attrs)
          yield t if block_given?
        end
      end
    else
      content_tag(:div, ti(:no_list_entries), class: 'table')
    end
  end

  # Renders a generic form for the given object using StandardFormBuilder.
  def standard_form(object, options = {}, &block)
    options[:builder] ||= StandardFormBuilder
    options[:html] ||= {}
    add_css_class options[:html], 'form-horizontal' unless options.delete(:stacked)
    add_css_class options[:html], 'form-noindent' if options.delete(:noindent)

    form_for(object, options, &block) + send(:after_nested_form_callbacks)
  end

  def toggle_link(active, url, active_title = nil, inactive_title = nil, label = nil)
    icon, method = active ? ['ok', :delete] : ['minus', :put]
    title = active ? active_title : inactive_title

    caption = icon(icon)
    caption << '&nbsp; '.html_safe << label if label
    link_to(caption,
            url,
            title: title,
            remote: true,
            method: method)
  end

  # Renders a simple unordered list, which will
  # simply render all passed items or yield them
  # to your block.
  def simple_list(items, ul_options = {})
    content_tag_nested(:ul, items, ul_options) do |item|
      content_tag(:li, block_given? ? yield(item) : f(item))
    end
  end

  # render a content tag with the collected contents rendered
  # by &block for each item in collection.
  def content_tag_nested(tag, collection, options = {}, &block)
    content_tag(tag, safe_join(collection, &block), options)
  end

  # Overridden method that takes a block that is executed for each item in array
  # before appending the results.
  def safe_join(array, sep = $OUTPUT_FIELD_SEPARATOR, &block)
    super(block_given? ? array.collect(&block).compact : array, sep)
  end


  # Translates the passed key by looking it up over the controller hierarchy.
  # The key is searched in the following order:
  #  - {controller}.{current_partial}.{key}
  #  - {controller}.{current_action}.{key}
  #  - {controller}.global.{key}
  #  - {parent_controller}.{current_partial}.{key}
  #  - {parent_controller}.{current_action}.{key}
  #  - {parent_controller}.global.{key}
  #  - ...
  #  - global.{key}
  def translate_inheritable(key, variables = {})
    defaults = []
    partial = @virtual_path ? @virtual_path.gsub(/.*\/_?/, '') : nil
    current = controller.class
    while current < ActionController::Base
      folder = current.controller_path
      if folder.present?
        defaults << :"#{folder}.#{partial}.#{key}" if partial
        defaults << :"#{folder}.#{action_name}.#{key}"
        defaults << :"#{folder}.global.#{key}"
      end
      current = current.superclass
    end
    defaults << :"global.#{key}"

    variables[:default] ||= defaults
    t(defaults.shift, variables)
  end

  alias_method :ti, :translate_inheritable

  # Translates the passed key for an active record association. This helper is used
  # for rendering association dependent keys in forms like :no_entry, :none_available or
  # :please_select.
  # The key is looked up in the following order:
  #  - activerecord.associations.models.{model_name}.{association_name}.{key}
  #  - activerecord.associations.{association_model_name}.{key}
  #  - global.associations.{key}
  def translate_association(key, assoc = nil, variables = {})
    primary =
      if assoc
        assoc_class_key = assoc.klass.model_name.to_s.underscore
        variables[:default] ||= [:"activerecord.associations.#{assoc_class_key}.#{key}",
                                 :"global.associations.#{key}"]
        owner_class_key = assoc.active_record.model_name.to_s.underscore
        "activerecord.associations.models.#{owner_class_key}.#{assoc.name}.#{key}"
      else
        "global.associations.#{key}"
      end
    t(primary, variables)
  end

  alias_method :ta, :translate_association


  # Returns the css class for the given flash level.
  def flash_class(level)
    case level
    when :notice then 'success'
    when :alert then 'error'
    else level.to_s
    end
  end

  # Adds a class to the given options, even if there are already classes.
  def add_css_class(options, classes)
    if options[:class]
      options[:class] += ' ' + classes
    else
      options[:class] = classes
    end
  end

  def model_class_label(entry)
    object_class(entry).model_name.human
  end

  def include_wysiwyg_assets
    content_for(:head)        { stylesheet_link_tag 'wysiwyg.css', media: 'all' }
    content_for(:js_includes) { javascript_include_tag 'wysiwyg' }
  end

  # Returns the ActiveRecord column type or nil.
  def column_type(obj, attr)
    column_property(obj, attr, :type)
  end

  # Returns an ActiveRecord column property for the passed attr or nil
  def column_property(obj, attr, property)
    if obj.respond_to?(:column_for_attribute)
      column = obj.column_for_attribute(attr)
      column.try(property)
    end
  end

  # Returns the association proxy for the given attribute. The attr parameter
  # may be the _id column or the association name. If a macro (e.g. :belongs_to)
  # is given, the association must be of this type, otherwise, any association
  # is returned. Returns nil if no association (or not of the given macro) was
  # found.
  def association(obj, attr, *macros)
    klass = object_class(obj)
    if klass.respond_to?(:reflect_on_association)
      name = assoc_and_id_attr(attr).first.to_sym
      assoc = klass.reflect_on_association(name)
      assoc if assoc && (macros.blank? || macros.include?(assoc.macro))
    end
  end

  # Returns the name of the attr and it's corresponding field
  def assoc_and_id_attr(attr)
    attr = attr.to_s
    if attr.end_with?('_id')
      [attr[0..-4], attr]
    elsif attr.end_with?('_ids')
      [attr[0..-5].pluralize, attr]
    else
      [attr, "#{attr}_id"]
    end
  end

  def format_column(type, val)
    return EMPTY_STRING if val.nil?
    case type
    when :time    then f(val.to_time)
    when :date    then f(val.to_date)
    when :datetime, :timestamp then "#{f(val.to_date)} #{f(val.to_time)}"
    when :text    then val.present? ? simple_format(h(val)) : EMPTY_STRING
    when :decimal then f(val.to_s.to_f)
    else f(val)
    end
  end

  private

  # Helper methods that are not directly called from templates.

  # Formats an arbitrary attribute of the given object depending on its data type.
  # For ActiveRecords, take the defined data type into account for special types
  # that have no own object class.
  def format_type(obj, attr)
    val = obj.send(attr)
    type = column_type(obj, attr)
    format_column(type, val)
  end

  # Formats an active record belongs_to association
  def format_assoc(obj, assoc)
    val = obj.send(assoc.name)
    if val
      assoc_link(val)
    else
      ta(:no_entry, assoc)
    end
  end

  # Formats an active record has_and_belongs_to_many or
  # has_many association.
  def format_many_assoc(obj, assoc)
    values = obj.send(assoc.name)
    if values.size == 1
      assoc_link(values.first)
    elsif values.present?
      simple_list(values) { |val| assoc_link(val) }
    else
      ta(:no_entry, assoc)
    end
  end

  # Renders a link to the given association entry.
  def assoc_link(val)
    link_to_if(assoc_link?(val), val.to_s, val)
  end

  # Returns true if no link should be created when formatting the given association.
  def assoc_link?(val)
    respond_to?("#{val.class.base_class.model_name.singular_route_key}_path".to_sym) &&
    can?(:show, val)
  end

  def object_class(obj)
    obj.respond_to?(:klass) ? obj.klass : obj.class
  end

end
