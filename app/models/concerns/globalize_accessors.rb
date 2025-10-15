# Copyright (c) 2009, 2010, 2011, 2012, 2013 Tomek "Tomash" Stachewicz,
# Robert Pankowecki, Chris Salzberg
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

module GlobalizeAccessors
  include ColumnHelper

  def globalize_accessors(options = {})
    options.reverse_merge!(locales: Globalized.languages, attributes: translated_attribute_names)
    class_attribute :globalize_locales, :globalize_attribute_names, instance_writer: false

    self.globalize_locales = options[:locales]
    self.globalize_attribute_names = []

    each_attribute_and_locale(options) do |attr_name, locale|
      define_accessors(attr_name, locale)
    end
  end

  def localized_attr_name_for(attr_name, locale)
    "#{attr_name}_#{locale.to_s.underscore}"
  end

  private

  def define_accessors(attr_name, locale)
    if ::ActiveRecord::VERSION::STRING >= "5.0"
      attribute("#{attr_name}_#{locale}", ::ActiveRecord::Type::Value.new)
    end
    define_getter(attr_name, locale)
    define_setter(attr_name, locale)
  end

  def define_getter(attr_name, locale)
    define_method localized_attr_name_for(attr_name, locale) do
      globalize.stash.contains?(locale, attr_name) ?
        globalize.send(:fetch_stash, locale, attr_name) :
        globalize.send(:fetch_attribute, locale, attr_name)
    end
    define_method "#{localized_attr_name_for(attr_name, locale)}_type" do
      self.class.column_type(self, attr_name)
    end
  end

  def define_setter(attr_name, locale)
    localized_attr_name = localized_attr_name_for(attr_name, locale)

    define_method :"#{localized_attr_name}=" do |value|
      attribute_will_change!(localized_attr_name) if value != send(localized_attr_name)
      self.attributes = {attr_name => value, :locale => locale}
      translation_for(locale).send(:"#{attr_name}=", value)
    end
    if respond_to?(:accessible_attributes) && accessible_attributes.include?(attr_name)
      attr_accessible :"#{localized_attr_name}"
    end
    globalize_attribute_names << localized_attr_name.to_sym
  end

  def each_attribute_and_locale(options)
    options[:attributes].each do |attr_name|
      options[:locales].each do |locale|
        yield attr_name, locale
      end
    end
  end
end
