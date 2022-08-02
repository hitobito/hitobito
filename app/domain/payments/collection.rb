# frozen_string_literal: true

#  Copyright (c) 2021-2022, Die Mitte. This file is part of
#  hitobito_die_mitte and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_die_mitte.

# Payments is already a namespace, therefore I went with the Javaism to name
# this class Payments::Collection.
class Payments::Collection
  attr_reader :payments

  class_attribute :invoice_item_group_attrs

  self.invoice_item_group_attrs = [:'invoice_items.name',
                                   :'invoice_items.account',
                                   :'invoice_items.cost_center']

  def initialize
    @payments = Payment.list
  end

  def from(timestamp)
    @payments = @payments.where(payments: { received_at: timestamp.. })

    self
  end

  def to(timestamp)
    @payments = @payments.where(payments: { received_at: ..timestamp })

    self
  end

  def in_last(duration)
    raise 'Has to be at least one year in the past' if duration.ago.year >= Time.zone.now.year

    from = duration.ago.beginning_of_year
    to = 1.year.ago.end_of_year
    @payments = @payments.where('payments.received_at >= ?' \
                                  'AND payments.received_at <= ?', from, to)

    self
  end

  def of_person(person)
    @payments = @payments.joins(:invoice).where(invoice: { recipient: person })

    self
  end

  def grouped_by_invoice_items
    @payments.joins('INNER JOIN invoices AS invoice ON invoice.id = payments.invoice_id')
             .joins('INNER JOIN invoice_items ON invoice.id = invoice_items.invoice_id')
             .group(invoice_item_group_attrs)
  end

  def of_fully_payed_invoices
    invoice_ids =
      @payments.select(:'invoice.total', :invoice_id)
               .joins('INNER JOIN invoices AS invoice ON invoice.id = payments.invoice_id')
               .having('SUM(payments.amount) >= invoice.total')
               .group(:invoice_id)
               .map(&:invoice_id)
    @payments = @payments.where(invoice_id: invoice_ids)

    self
  end

  def of_non_fully_payed_invoices
    invoice_ids =
      @payments.select(:'invoice.total', :invoice_id)
               .joins('INNER JOIN invoices AS invoice ON invoice.id = payments.invoice_id')
               .having('SUM(payments.amount) < invoice.total')
               .group(:invoice_id)
               .map(&:invoice_id)
    @payments = @payments.where(invoice_id: invoice_ids)

    self
  end

  def in_layer(layer)
    @payments = @payments.joins(:invoice).where(invoice: { group: layer })

    self
  end

  def previous_amount(options = {})
    if options[:increased_by]
      increased_amount = payment_sum * (1.0 + options[:increased_by].to_f / 100.0)
      case payment_sum
      when   0..99  then round_to_nearest(5.0, increased_amount)
      when 100..999 then round_to_nearest(10.0, increased_amount)
      else               round_to_nearest(50.0, increased_amount)
      end
    else
      payment_sum
    end
  end

  private

  def payment_sum
    @payments.sum(:amount)
  end

  def round_to_nearest(target, value)
    (value / target.to_f).round * target.to_f
  end
end
