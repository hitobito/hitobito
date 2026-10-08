# frozen_string_literal: true

#  Copyright (c) 2012-2026, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class InvoiceAbility < AbilityDsl::Base
  on(Invoice) do
    permission(:finance).may(:index).in_layer_if_active
    permission(:finance).may(:show).in_layer
    permission(:finance).may(:create, :edit, :update, :destroy).in_layer_if_active
  end

  on(InvoiceItem) do
    permission(:finance).may(:show, :index).in_invoice_layer
    permission(:finance).may(:create, :edit, :update, :destroy).in_invoice_layer_if_active
  end

  on(InvoiceRun) do
    permission(:finance).may(:show, :update, :destroy).in_layer_if_active
    permission(:finance).may(:create).in_layer_with_recipient_source
    permission(:finance).may(:index_invoices).in_layer_with_recipient_source_if_active
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
    permission(:finance).may(:create).in_invoice_layer
    permission(:finance).may(:index).in_invoice_layer
  end

  on(PeriodInvoiceTemplate) do
    permission(:finance).may(:show, :index).in_layer
    permission(:finance).may(:new, :create, :edit, :update).in_layer_if_active
  end

  on(PaymentReminder) do
    permission(:finance).may(:create).in_invoice_layer_if_active
  end

  def in_layer
    {group: finance_layer_groups}
  end

  def in_layer_if_active
    {group: active_finance_layer_groups}
  end

  def in_invoice_layer
    {invoice: in_layer}
  end

  def in_invoice_layer_if_active
    {invoice: in_layer_if_active}
  end

  def in_layer_with_recipient_source
    all_of(in_layer, recipient_source_in(finance_layer_groups))
  end

  def in_layer_with_recipient_source_if_active
    all_of(in_layer, recipient_source_in(active_finance_layer_groups))
  end

  private

  def finance_layer_groups
    {layer_group_id: user_finance_layer_ids}
  end

  def active_finance_layer_groups
    finance_layer_groups.merge(archived_at: nil)
  end

  # Recipient sources may be new records, which is why their associations are matched
  # instead of a subquery. Lists of invoice runs are not filtered by these conditions.
  def recipient_source_in(groups)
    any_of({recipient_source_type: nil},
      {recipient_source_type: MailingList.sti_name, recipient_source: {group: groups}},
      {recipient_source_type: PeopleFilter.sti_name, recipient_source: {group: groups}},
      {recipient_source_type: GroupsFilter.sti_name, recipient_source: {parent: groups}},
      {recipient_source_type: Event::ParticipationsFilter.sti_name,
       recipient_source: {event: {groups: groups}}})
  end
end
