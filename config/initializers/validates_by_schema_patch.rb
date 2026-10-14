# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

module ValidatesBySchema
  module IgnoreSequenceDefaultColumns
    private

    def ignored_columns_for_validates_by_schema
      super + columns.select { |c| c.default_function&.start_with?("nextval(") }.map(&:name)
    end
  end

  ClassMethods.prepend(IgnoreSequenceDefaultColumns)
end
