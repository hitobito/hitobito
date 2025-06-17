# frozen_string_literal: true

#  Copyright (c) 2012-2025, Swiss Badminton. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module InvoiceLists
  class RoleItem < Item
    def initialize(fee:, key:, unit_cost:, roles:, layer_group_ids: nil)
      super(fee:, key:, unit_cost:, layer_group_ids:)
      @roles = roles
    end

    def scope = Role.joins(:group).where(type: @roles)
  end
end
