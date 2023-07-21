# frozen_string_literal: true

#  Copyright (c) 2022, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Invoice::ItemEvaluation
  def initialize(group, from, to)
    @group = group
    @from = from
    @to = to
  end

  def fetch_evaluations
    rows = []
    rows += rows_by_invoice_article

    rows << deficit_row if sum_of_deficitary_payments.nonzero?
    rows << excess_row  if excess_amount.nonzero?

    rows
  end

  def total
    relevant_payments.excluding_cancelled_invoices.payments.sum(:amount)
  end

  private

  def rows_by_invoice_article # rubocop:disable Metrics/MethodLength
    @rows_by_invoice_article ||= invoice_article_identifiers.collect do |ids|
      name, account, cost_center = ids
      {
        name: name,
        vat: invoice_item_vats(*ids),
        count: count(*ids),
        amount_paid: amount_paid_without_vat(*ids) + invoice_item_vats(*ids),
        account: account,
        cost_center: cost_center,
        type: :by_article
      }
    end.uniq
  end

  def invoice_article_total_amount
    rows_by_invoice_article.sum { |article| article[:amount_paid] }
  end

  def payments_of_paid_invoices
    @payments_of_paid_invoices ||=
      relevant_payments.of_fully_paid_invoices
                       .excluding_cancelled_invoices
  end

  def deficitary_payments
    @deficit_payments = relevant_payments.of_non_fully_paid_invoices.payments
  end

  def relevant_payments
    Payments::Collection.new
                        .in_layer(@group)
                        .from(@from)
                        .to(@to)
  end

  def sum_of_deficitary_payments
    deficitary_payments.sum(:amount)
  end

  def deficit_row
    {
      name: I18n.t('invoices.evaluations.show.deficit'),
      vat: '',
      count: deficitary_payments.count,
      amount_paid: sum_of_deficitary_payments,
      account: '',
      cost_center: '',
      type: :deficit
    }
  end

  def excess_amount
    # total of all payments - (the amount assigned to articles + partial/deficitary payments)
    total - (invoice_article_total_amount + sum_of_deficitary_payments)
  end

  def excess_row
    {
      name: I18n.t('invoices.evaluations.show.excess'),
      vat: '',
      count: '',
      amount_paid: excess_amount,
      account: '',
      cost_center: '',
      type: :excess
    }
  end

  def count(name, account, cost_center)
    # Get the relevant invoices
    relevant_invoice_ids = payments_of_paid_invoices.payments.pluck(:invoice_id)

    # Search invoice items which fit the identifiers and are attached to relevant payments
    invoice_items = InvoiceItem.where(name: name,
                                      account: account,
                                      cost_center: cost_center,
                                      invoice_id: relevant_invoice_ids)

    amount_of_invoices = invoice_items.pluck(:invoice_id).uniq.size

    # We get the total count by multiplying the count of the item with the amount of found invoices
    invoice_items.first.count * amount_of_invoices
  end

  def invoice_item_vats(name, account, cost_center)
    # Get the relevant invoices
    relevant_invoice_ids = relevant_payments.of_fully_paid_invoices.payments.pluck(:invoice_id)

    # Search invoice item which fits the identifiers and are attached to relevant payments
    invoice_item = InvoiceItem.find_by(name: name,
                                       account: account,
                                       cost_center: cost_center,
                                       invoice_id: relevant_invoice_ids)

    # Invoice items with an empty vat_rate will be 0
    return 0 unless invoice_item.vat_rate&.nonzero?

    # We get the vat by multiplying the vat_rate with the paid amount excluding vat
    invoice_item.vat_rate / 100 * amount_paid_without_vat(name, account, cost_center)
  end

  def amount_paid_without_vat(name, account, cost_center)
    relevant_invoice_ids = payments_of_paid_invoices.payments.pluck(:invoice_id)

    invoice_item = InvoiceItem.find_by(name: name,
                                       account: account,
                                       cost_center: cost_center,
                                       invoice_id: relevant_invoice_ids)

    count(name, account, cost_center) * invoice_item.unit_cost
  end

  def invoice_article_identifiers
    # Used for the group statement, thus being identifiers/key when doing calculation
    # Is used to get all identifiers and then loop to calculate/fetch the values for each article

    payments_of_paid_invoices.grouped_by_invoice_items
                             .pluck(*Payments::Collection.invoice_item_group_attrs)
  end
end
