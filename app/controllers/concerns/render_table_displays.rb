# frozen_string_literal: true

# Copyright (c) 2022, Pfadibewegung Schweiz. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https ://github.com/hitobito/hitobito.

module RenderTableDisplays

  def list_entries
    add_table_display_selects(super, current_person)
  end

  private

  def add_table_display_selects(scope, person)
    # preserve previously selected columns
    previous = scope.select_values.presence || [scope.model.arel_table[Arel.star]]
    scope.select((previous + table_display_selects(person)).uniq)
  end

  def table_display_selects(person)
    TableDisplay.active_columns_for(person, model_class).flat_map do |column|
      person
          .table_display_for(model_class)
          .column_for(column)
          .required_model_attrs(column)
          .map(&:to_s)
    end
  end

end
