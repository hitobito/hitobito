# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# A view helper to standartize often used functions like formatting,
# tables, forms or action links. This helper is ideally defined in the
# ApplicationController.
module FormatHelper

  EMPTY_STRING = '&nbsp;'.html_safe # non-breaking space asserts better css styling.

  ################  FORMATTING HELPERS  ##################################

  # Formats a single value
  # (integers are not formatted, since years etc. should not contain delimiters)
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

  # Formats single decimal and integer values
  def fnumber(value)
    case value
    when Float, BigDecimal then
      number_with_precision(value, precision: t('number.format.precision'),
                                   delimiter: t('number.format.delimiter'))
    when nil then EMPTY_STRING
    else
      number_with_delimiter(value.to_i, delimiter: t('number.format.delimiter'))
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
    end.gsub(/\//, '_') # deal with nested models
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
    return if attrs.blank?
    content = safe_join(attrs) do |a|
      labeled_attr(obj, a) if !block_given? || yield(a)
    end
    content_tag(:dl, content, class: 'dl-horizontal') if content.present?
  end

  # Like #render_attrs, but only for attributes with a present value.
  def render_present_attrs(obj, *attrs)
    render_attrs(obj, *attrs) do |a|
      obj.send(a).present? || obj.send(a).is_a?(FalseClass)
    end
  end

  # Renders the formatted content of the given attribute with a label.
  def labeled_attr(obj, attr)
    labeled(captionize(attr, object_class(obj)), format_attr(obj, attr))
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
