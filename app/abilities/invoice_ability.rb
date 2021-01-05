# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class InvoiceAbility < AbilityDsl::Base

  on(Invoice) do
    permission(:finance).may(:create, :show, :edit, :update, :destroy).in_layer
  end

  on(InvoiceList) do
    permission(:finance).may(:create, :show, :edit, :update, :destroy).in_layer_with_receiver
  end

  on(InvoiceArticle) do
    permission(:finance).may(:new, :create, :show, :edit, :update, :destroy).in_layer
  end

  on(InvoiceConfig) do
    permission(:finance).may(:show, :edit, :update).in_layer
  end

  on(Payment) do
    permission(:finance).may(:create).in_layer
  end

  on(PaymentReminder) do
    permission(:finance).may(:create).in_layer
  end

  def any_finance_group
    user.finance_groups.present?
  end

  def in_layer(group = subject.group)
    user.groups_with_permission(:finance).collect(&:layer_group).include?(group)
  end

  def in_layer_with_receiver
    return in_layer unless subject.receiver
    in_layer && in_layer(subject.receiver.group.layer_group)
  end

end
