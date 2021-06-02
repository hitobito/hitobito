# frozen_string_literal: true

#  Copyright (c) 2021, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Events::Filter
  class CourseKindCategory
    def initialize(_user, params, _options, scope)
      @params = params
      @scope = scope
    end

    def to_scope
      return @scope unless kind_category_id.present?

      scope = @scope.left_joins(kind: :kind_category)
      return scope.where('event_kinds.kind_category_id IS NULL') if kind_category_id == '0'

      scope.where('event_kind_categories.id = :category', category: kind_category_id)
    end

    private

    def kind_category_id
      @params.dig(:filter, :category)
    end
  end
end
