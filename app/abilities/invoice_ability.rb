# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class InvoiceAbility < AbilityDsl::Base

  on(Invoice) do
    permission(:finance).may(:create, :show, :edit, :update, :destroy).in_layer
    class_side(:index).any_finance_group
  end

  on(InvoiceArticle) do
    permission(:finance).may(:index, :new, :create, :show, :edit, :update, :destroy).in_layer
  end

  on(InvoiceConfig) do
    permission(:finance).may(:create, :show, :edit, :update, :destroy).in_layer
  end

  def any_finance_group
    user.finance_groups.present?
  end

  def in_layer
    user.groups_with_permission(:finance).collect(&:layer_group).include?(subject.group)
  end

end
