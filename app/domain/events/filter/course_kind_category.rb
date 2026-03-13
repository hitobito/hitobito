# frozen_string_literal: true

#  Copyright (c) 2021, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Events::Filter
  class CourseKindCategory < Filter::Base
    self.permitted_args = [:id]

    def apply(scope)
      id = (kind_category_id.to_s == "0") ? nil : kind_category_id
      scope
        .left_joins(:kind)
        .where(event_kinds: {kind_category_id: id})
    end

    def blank?
      !Event::Course.attr_used?(:kind_id) || super
    end

    private

    def kind_category_id
      args[:id]
    end
  end
end
