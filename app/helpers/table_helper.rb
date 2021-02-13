#  Copyright (c) 2012-2019, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module TableHelper

  # Renders a table for the given entries. One column is rendered for each attribute passed.
  # If a block is given, the columns defined therein are appended to the attribute columns.
  # If entries is empty, an appropriate message is rendered.
  # An options hash may be given as the last argument.
  def table(entries, *attrs) # rubocop:disable Metrics/MethodLength
    entries.to_a # force evaluation of relation
    if entries.present?
      content_tag(:div, class: "table-responsive") do
        StandardTableBuilder.table(entries, self, attrs.extract_options!) do |t|
          t.attrs(*attrs)
          yield t if block_given?
        end
      end
    else
      content_tag(:div, ti(:no_list_entries), class: "table")
    end
  end

  # Create a table of the entries with the default or
  # the passed attributes in its columns. An options hash may be given
  # as the last argument.
  def list_table(*attrs)
    options = attrs.extract_options!
    add_css_class(options, "table table-striped table-hover")
    # only use default attrs if no attrs and no block are given
    attributes = block_given? || attrs.present? ? attrs : default_attrs
    table(entries, options) do |t|
      t.sortable_attrs(*attributes)
      yield t if block_given?
    end
  end

  # Create a table of the entries with the default or
  # the passed attributes in its columns. An options hash may be given
  # as the last argument.
  def crud_table(*attrs, &block)
    if block_given?
      list_table(*attrs, &block)
    else
      attrs = attrs_or_default(attrs) { default_attrs }
      list_table(*attrs) do |t|
        add_table_actions(t)
      end
    end
  end

  # Adds a set of standard action link column (show, edit, destroy) to the given table.
  def add_table_actions(table)
    action_col_edit(table)
    action_col_destroy(table)
  end

  # Action link to edit inside a table.
  # A block may be given to define the link path for the row entry.
  def action_col_edit(table, &block)
    action_col(table) do |e|
      link_action_edit(action_path(e, &block)) if can?(:edit, e)
    end
  end

  # Action link to destroy inside a table.
  # A block may be given to define the link path for the row entry.
  def action_col_destroy(table, &block)
    action_col(table) do |e|
      # paranoid entries may be destroyed but still be in the database
      if can?(:destroy, e) && (!e.respond_to?(:deleted?) || !e.deleted?)
        link_action_destroy(action_path(e, &block))
      end
    end
  end

  # Defines a column with an action link.
  def action_col(table, &block)
    table.col("", class: "action", &block)
  end

  # The default attributes to use in attrs, list and form partials.
  # These are all defined attributes except certain special ones like 'id' or 'position'.
  def default_attrs
    attrs = model_class.column_names.collect(&:to_sym)
    attrs - [:id, :position, :password]
  end

  # Returns default attrs for a crud table if no others are passed.
  def attrs_or_default(attrs)
    options = attrs.extract_options!
    attrs = yield if attrs.blank?
    attrs << options
  end

end
