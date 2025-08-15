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
    rows += article_rows

    rows << deficit_row if sum_of_deficitary_payments.nonzero?
    rows << excess_row if excess_amount.nonzero?

    rows
  end

  def total
    relevant_payments.excluding_cancelled_invoices.payments.sum(:amount)
  end

  private

  # rubocop:todo Metrics/MethodLength
  # rubocop:todo Metrics/AbcSize
  def article_rows # rubocop:todo Metrics/CyclomaticComplexity # rubocop:todo Metrics/AbcSize
    return @article_rows if @article_rows.present?

    # rubocop:todo Layout/LineLength
    invoice_items_by_article = InvoiceItem.where(invoice_id: payments_of_paid_invoices.payments.pluck(:invoice_id).uniq)
      # rubocop:enable Layout/LineLength
      .group_by { |invoice_item|
      [invoice_item.name, invoice_item.account,
        invoice_item.cost_center]
    }

    @article_rows = invoice_items_by_article.map do |ids, invoice_items|
      name, account, cost_center = *ids

      {
        name: name,
        vat: invoice_items.sum { |invoice_item| InvoiceItems::Calculation.round(invoice_item.vat) },
        count: invoice_items.sum(&:count),
        amount_paid: invoice_items.sum { |invoice_item|
          InvoiceItems::Calculation.round(invoice_item.total)
        },
        account: account,
        cost_center: cost_center,
        type: :by_article
      }
    end
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength

  def invoice_article_total_amount
    article_rows.sum { |article| article[:amount_paid] }
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
      name: I18n.t("invoices.evaluations.show.deficit"),
      vat: "",
      count: deficitary_payments.count,
      amount_paid: sum_of_deficitary_payments,
      account: "",
      cost_center: "",
      type: :deficit
    }
  end

  def excess_amount
    # total of all payments - (the amount assigned to articles + partial/deficitary payments)
    total - (invoice_article_total_amount + sum_of_deficitary_payments)
  end

  def excess_row
    {
      name: I18n.t("invoices.evaluations.show.excess"),
      vat: "",
      count: "",
      amount_paid: excess_amount,
      account: "",
      cost_center: "",
      type: :excess
    }
  end
end
