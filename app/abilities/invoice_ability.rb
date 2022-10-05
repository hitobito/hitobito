# frozen_string_literal: true

#  Copyright (c) 2012-2021, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class InvoiceAbility < AbilityDsl::Base

  on(Invoice) do
    permission(:finance).may(:show).in_layer
    permission(:finance).may(:create, :edit, :update, :destroy).in_layer_if_active
  end

  on(InvoiceList) do
    permission(:finance).may(:update, :destroy).in_layer_if_active
    permission(:finance).may(:create).in_layer_with_receiver
    permission(:finance).may(:index_invoices).in_layer_with_receiver_if_active
  end

  on(InvoiceArticle) do
    permission(:finance).may(:show).in_layer
    permission(:finance).may(:new, :create, :edit, :update, :destroy).in_layer_if_active
  end

  on(InvoiceConfig) do
    permission(:finance).may(:show).in_layer
    permission(:finance).may(:edit, :update).in_layer_if_active
  end

  on(Payment) do
    permission(:finance).may(:create).in_layer
  end

  on(PaymentReminder) do
    permission(:finance).may(:create).in_layer_if_active
  end

  def any_finance_group
    user.finance_groups.present?
  end

  def in_layer(group = subject.group)
    user.groups_with_permission(:finance).collect(&:layer_group).include?(group)
  end

  def in_layer_with_receiver
    return in_layer unless subject.receiver

    group = subject.receiver.is_a?(Group) ? subject.receiver : subject.receiver.group
    in_layer && in_layer(group.layer_group)
  end

  def in_layer_if_active
    in_layer && !subject.group&.archived?
  end

  def in_layer_with_receiver_if_active
    in_layer_with_receiver && !subject.receiver.group.archived?
  end

end
