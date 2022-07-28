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

    rows << deficit_row if deficit_amount.nonzero?

    rows << excess_row if excess_amount.nonzero?

    rows
  end
  
  def total
    relevant_payments.payments.sum(:amount)
  end

  private

  def rows_by_invoice_article
    @rows_by_invoice_article ||= invoice_article_identifiers.collect do |ids|
      name, account, cost_center = ids
      invoice_item = InvoiceItem.find_by(name: name, account: account, cost_center: cost_center)
      {
        name: name,
        vat: invoice_item_vats[ids],
        count: count(ids),
        amount_payed: count(ids) * invoice_item.unit_cost + invoice_item_vats[ids],
        account: account,
        cost_center: cost_center
      }
    end.uniq
  end

  def invoice_article_total_amount
    rows_by_invoice_article.sum { |article| article[:amount_payed] }
  end

  def payments_of_payed_invoices
    @payments_of_payed_invoices ||= relevant_payments
      .of_fully_payed_invoices
      .grouped_by_invoice_items
  end

  def deficit_payments
    @deficit_payments = relevant_payments
      .of_non_fully_payed_invoices
      .payments
  end

  def relevant_payments
    PaymentCollector.new.in_layer(@group)
      .from(@from)
      .to(@to)
  end

  def deficit_amount
    deficit_payments.sum(:amount)
  end

  def deficit_row
    {
      name: I18n.t('invoices.evaluations.show.deficit'),
      vat: '',
      count: deficit_payments.count,
      amount_payed: deficit_amount,
      account: '',
      cost_center: ''
    }
  end

  def excess_amount
    # total of all payments - (the amount assigned to articles + the deficit)
    total - (invoice_article_total_amount + deficit_amount)
  end

  def excess_row
    {
      name: I18n.t('invoices.evaluations.show.excess'),
      vat: '',
      count: '',
      amount_payed: excess_amount,
      account: '',
      cost_center: ''
    }
  end

  def count(ids)
    # Get the individual identifiers
    name, account, cost_center = ids

    # Get the relevant invoices
    relevant_invoice_ids = relevant_payments.of_fully_payed_invoices.payments.pluck(:invoice_id)

    # Search invoice items which fit the identifiers and are attached to relevant payments
    invoice_items = InvoiceItem.where(name: name,
                                      account: account,
                                      cost_center: cost_center,
                                      invoice_id: relevant_invoice_ids)

    amount_of_invoices = invoice_items.pluck(:invoice_id).uniq.size

    # We get the total count by multiplying the count of the item with the amount of found invoices
    invoice_items.first.count * amount_of_invoices
  end

  def invoice_item_vats
    # First convert the vat_rate to decimal,
    # multiply with the total cost to get the absolute payed vats.
    # Then sum those grouped by invoice item
    payments_of_payed_invoices.sum('(IFNULL(vat_rate, 0) / 100) * (count * unit_cost)')
  end

  def invoice_article_identifiers
    # Used for the group statement, thus being identifiers/key when doing calculation
    # Is used to get all identifiers and then loop to calculate/fetch the values for each article
    payments_of_payed_invoices.pluck(*PaymentCollector.invoice_item_group_attrs)
  end
end
