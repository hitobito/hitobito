# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class InvoiceAbility < AbilityDsl::Base

  on(Invoice) do
    permission(:finance).may(:create, :show, :edit, :update, :destroy).in_same_group
  end

  def in_same_group
    user.groups_with_permission(permission).include?(subject.group)
  end

end
