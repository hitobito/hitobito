# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class InvoiceAbility < AbilityDsl::Base

  on(Invoice) do
    permission(:admin).may(:create, :show, :edit, :update, :destroy).in_same_group
    permission(:finance).may(:create, :show, :edit, :update, :destroy).in_same_group

    class_side(:index).any_finance_group
  end

  on(InvoiceArticle) do
    permission(:finance).may(:index, :new, :create, :show, :edit, :update, :destroy).everybody
  end

  def in_same_group
    user.finance_groups.include?(subject.group)
  end

  def any_finance_group
    user.finance_groups.present?
  end

end
