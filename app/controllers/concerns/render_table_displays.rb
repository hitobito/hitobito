# frozen_string_literal: true

# Copyright (c) 2022, Pfadibewegung Schweiz. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https ://github.com/hitobito/hitobito.

module RenderTableDisplays
  def list_entries
    return super if sorting?
    add_table_display_to_query(super, current_person, group)
  end

  private

  def add_table_display_to_query(scope, person, selected_group)
    add_table_display_joins(scope, person, selected_group)
    add_table_display_selects(scope, person, selected_group)
  end

  def add_table_display_joins(scope, person, selected_group)
    scope.joins(table_display_joins(person, selected_group))
  end

  def table_display_joins(person, selected_group)
    TableDisplay.active_columns_for(person, model_class).map do |column|
      column_class = person.table_display_for(model_class).column_for(column)

      column_class.required_model_joins(column) unless column_class.exclude_attr?(selected_group)
    end
  end

  def add_table_display_selects(scope, person, selected_group)
    # preserve previously selected columns
    previous = scope.select_values.presence || [scope.model.arel_table[Arel.star]]
    scope.select((previous + table_display_selects(person, selected_group)).uniq).includes(table_display_includes(person, selected_group))
  end

  def table_display_selects(person, selected_group)
    TableDisplay.active_columns_for(person, model_class).flat_map do |column|
      column_class = person.table_display_for(model_class).column_for(column)

      column_class.safe_required_model_attrs(column).map(&:to_s) unless column_class.exclude_attr?(selected_group)
    end
  end

  def table_display_includes(person, selected_group)
    TableDisplay.active_columns_for(person, model_class).map do |column|
      column_class = person.table_display_for(model_class).column_for(column)

      column_class.required_model_includes(column) unless column_class.exclude_attr?(selected_group)
    end
  end
end
