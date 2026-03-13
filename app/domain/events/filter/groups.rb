# frozen_string_literal: true

#  Copyright (c) 2021, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Events::Filter
  class Groups < Filter::Base
    self.permitted_args = [:ids]

    def apply(scope)
      scope.with_group_id(group_ids)
    end

    def blank?
      group_ids.blank?
    end

    private

    def group_ids
      args[:ids].to_a.compact_blank
    end
  end
end
