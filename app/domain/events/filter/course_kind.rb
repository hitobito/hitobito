# frozen_string_literal: true

#  Copyright (c) 2021, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Events::Filter
  class CourseKind < Base
    self.permitted_args = [:id]

    def apply(scope)
      scope.where(kind_id: kind_ids)
    end

    def blank?
      !Event::Course.attr_used?(:kind_id) || kind_ids.blank?
    end

    private

    def kind_ids
      Array(args[:id]).compact_blank.map(&:to_i)
    end
  end
end
