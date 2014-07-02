# encoding: utf-8
# rubocop:disable Attr

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# A simple helper to easily define tables listing several rows of the same data type.
#
# Example Usage:
#   StandardTableBuilder.table(entries, template) do |t|
#     t.col('My Header', :class => 'css') {|e| link_to 'Show', e }
#     t.attrs :name, :city
#   end
class StandardTableBuilder
  attr_reader :entries, :cols, :options, :template

  # Delegate called methods to template.
  # including StandardHelper would lead to problems with indirectly called methods.
  delegate :content_tag, :format_attr, :column_type, :association, :dom_id,
           :captionize, :add_css_class, :content_tag_nested, to: :template

  def initialize(entries, template, options = {})
    @entries = entries
    @template = template
    @options = options
    @cols = []
  end

  # Convenience method to directly generate a table. Renders a row for each entry in entries.
  # Takes a block that gets the table object as parameter for configuration.
  # Returns the generated html for the table.
  def self.table(entries, template, options = {})
    t = new(entries, template, options)
    yield t
    t.to_html
  end

  # Define a column for the table with the given header, the html_options used for
  # each td and a block rendering the contents of a cell for the current entry.
  # The columns appear in the order they are defined.
  def col(header = '', html_options = {}, &block)
    @cols << Col.new(header, html_options, @template, block)
  end

  # Convenience method to add one or more attribute columns.
  # The attribute name will become the header, the cells will contain
  # the formatted attribute value for the current entry.
  def attrs(*attrs)
    attrs.each do |a|
      attr(a)
    end
  end

  # Define a column for the given attribute and an optional header.
  # If no header is given, the attribute name is used. The cell will
  # contain the formatted attribute value for the current entry.
  def attr(a, header = nil)
    header ||= attr_header(a)
    col(header, class: align_class(a)) { |e| format_attr(e, a) }
  end

  # Renders the table as HTML.
  def to_html
    content_tag :table, options do
      content_tag(:thead, html_header) +
      content_tag_nested(:tbody, entries) { |e| html_row(e) }
    end
  end

  # Returns css classes used for alignment of the cell data.
  # Based on the column type of the attribute.
  def align_class(attr)
    entry = entry_class.respond_to?(:new) ? entry_class.new : nil
    case column_type(entry, attr)
    when :integer, :float, :decimal
      'right' unless association(entry, attr, :belongs_to)
    when :boolean
      'center'
    end
  end

  def attr_header(attr)
    captionize(attr, entry_class)
  end

  private

  def html_header
    content_tag_nested(:tr, cols) { |c| c.html_header }
  end

  def html_row(entry)
    attrs = {}
    attrs[:id] = dom_id(entry) if entry.respond_to?(:to_key)
    content_tag_nested(:tr, cols, attrs) { |c| c.html_cell(entry) }
  end

  def entry_class
    if entries.respond_to?(:klass)
      entries.klass
    elsif entries.respond_to?(:decorator_class)
      entries.decorator_class.object_class
    else
      entries.first.class
    end
  end

  # Helper class to store column information.
  class Col < Struct.new(:header, :html_options, :template, :block) #:nodoc:

    delegate :content_tag, to: :template

    def content(entry)
      entry.nil? ? '' : template.capture(entry, &block)
    end

    def html_header
      content_tag :th, header, html_options
    end

    def html_cell(entry)
      content_tag :td, content(entry), html_options
    end

  end

  # Provides headers with sort links. Expects a method :sortable?(attr)
  # in the template/controller to tell if an attribute is sortable or not.
  # Extracted into an own module for convenience.
  module Sorting
    # Create a header with sort links and a mark for the current sort direction.
    def sort_header(attr, label = nil)
      label ||= attr_header(attr)
      template.link_to(label, sort_params(attr)) + current_mark(attr)
    end

    # Same as :attrs, except that it renders a sort link in the header
    # if an attr is sortable.
    def sortable_attrs(*attrs)
      attrs.each do |a|
        template.sortable?(a) ? sortable_attr(a) : attr(a)
      end
    end

    # Renders a sort link header, otherwise similar to :attr.
    def sortable_attr(a, header = nil)
      attr(a, sort_header(a, header))
    end

    private

    # Request params for the sort link.
    def sort_params(attr)
      params.merge(sort: attr, sort_dir: sort_dir(attr))
    end

    # The sort mark, if any, for the given attribute.
    def current_mark(attr)
      if current_sort?(attr)
        (sort_dir(attr) == 'asc' ? ' &uarr;' : ' &darr;').html_safe
      else
        ''
      end
    end


    # Returns true if the given attribute is the current sort column.
    def current_sort?(attr)
      params[:sort] == attr.to_s
    end

    # The sort direction to use in the sort link for the given attribute.
    def sort_dir(attr)
      current_sort?(attr) && params[:sort_dir] == 'asc' ? 'desc' : 'asc'
    end

    # Delegate to template.
    def params
      template.params
    end
  end

  include Sorting

end
