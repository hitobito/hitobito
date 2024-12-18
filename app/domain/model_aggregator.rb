# frozen_string_literal: true

#  Copyright (c) 2017-2024, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class ModelAggregator
  def initialize(model_class)
    @model_class = model_class
  end

  def aggregated_columns(aggregate_function = "MAX")
    @model_class.columns.map do |column|
      if column.type == :boolean
        "BOOL_OR(#{@model_class.table_name}.#{column.name}) AS #{column.name}"
      else
        "#{aggregate_function}(#{@model_class.table_name}.#{column.name}) AS #{column.name}"
      end
    end.join(", ")
  end  
end
