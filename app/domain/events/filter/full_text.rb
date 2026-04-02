# frozen_string_literal: true

#  Copyright (c) 2021, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Events::Filter
  class FullText < Base
    MIN_QUERY_LENGTH = 3
    SEARCHABLE_ATTRIBUTES = %w[
      event_translations.name
      event_translations.description
      events.location
    ]

    self.permitted_args = [:q]

    def apply(scope)
      scope.where(search_condition)
    end

    def blank?
      query.size < MIN_QUERY_LENGTH
    end

    private

    def search_condition
      SearchStrategies::SqlConditionBuilder.new(query, SEARCHABLE_ATTRIBUTES).search_conditions
    end

    def query
      args[:q].to_s.strip
    end
  end
end
