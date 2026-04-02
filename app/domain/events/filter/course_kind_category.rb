# frozen_string_literal: true

#  Copyright (c) 2021, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Events::Filter
  class CourseKindCategory < Base
    self.permitted_args = [:id]

    def apply(scope)
      scope
        .left_joins(:kind)
        .where(event_kinds: {kind_category_id: kind_category_ids})
    end

    def blank?
      !Event::Course.attr_used?(:kind_id) || kind_category_ids.blank?
    end

    private

    def kind_category_ids
      Array(args[:id]).compact_blank.map(&:to_i).map { |id| (id == 0) ? nil : id }
    end
  end
end
