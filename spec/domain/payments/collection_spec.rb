# frozen_string_literal: true

#  Copyright (c) 2021, Die Mitte. This file is part of
#  hitobito_die_mitte and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_die_mitte.

require 'spec_helper'

describe Payments::Collection do
  let(:top_leader) { people(:top_leader) }
  let(:top_layer) { groups(:top_layer) }
  let(:bottom_member) { people(:bottom_member) }


  context 'in_last' do
    it 'does not allow current year' do
      expect do
        described_class.new.in_last(1.second)
      end.to raise_error('Has to be at least one year in the past')
    end

    it 'considers whole year' do
      fabricated_payment1 = fabricate_payment(50.0, Date.new(1.year.ago.year, 1, 1))
      fabricated_payment2 = fabricate_payment(50.0, Date.new(1.year.ago.year, 7, 20))
      fabricated_payment3 = fabricate_payment(50.0, Date.new(1.year.ago.year, 12, 31))

      payments = described_class.new.in_last(1.year).instance_variable_get(:@payments)

      expect(payments.size).to eq(3)
      expect(payments).to include(fabricated_payment1)
      expect(payments).to include(fabricated_payment2)
      expect(payments).to include(fabricated_payment3)
    end

    it 'considers multiple whole years' do
      fabricated_payment1 = fabricate_payment(50.0, Date.new(3.years.ago.year, 1, 1))
      fabricated_payment2 = fabricate_payment(50.0, Date.new(2.years.ago.year, 3, 20))
      fabricated_payment3 = fabricate_payment(50.0, Date.new(1.year.ago.year, 12, 31))

      payments = described_class.new.in_last(3.years).instance_variable_get(:@payments)

      expect(payments.size).to eq(3)
      expect(payments).to include(fabricated_payment1)
      expect(payments).to include(fabricated_payment2)
      expect(payments).to include(fabricated_payment3)
    end

    it 'does not find payment outside of duration' do
      fabricate_payment(50.0, Date.new(2.year.ago.year, 3, 20))

      payments = described_class.new.in_last(1.year).instance_variable_get(:@payments)

      expect(payments).to be_empty
    end
  end

  context 'of_fully_paid_invoices' do
    it 'lists payments to fully paid invoices' do
      invoice_item_attrs = [{
        name: 'Shirt',
        description: 'Good quality',
        unit_cost: 50,
        count: 1,
      }]

      fabricated_payment1 = fabricate_payment(50.0, Date.new(3.years.ago.year, 1, 1))
      fabricated_payment2 = fabricate_payment(50.0, Date.new(2.years.ago.year, 3, 20))
      fabricated_payment3 = fabricate_payment(50.0, Date.new(1.year.ago.year, 12, 31))

      fabricated_payment1.invoice.update(invoice_items_attributes: invoice_item_attrs)
      fabricated_payment2.invoice.update(invoice_items_attributes: invoice_item_attrs)
      fabricated_payment3.invoice.update(invoice_items_attributes: invoice_item_attrs)

      payments = described_class.new.of_fully_paid_invoices.instance_variable_get(:@payments)

      expect(payments.size).to eq(3)
      expect(payments).to include(fabricated_payment1)
      expect(payments).to include(fabricated_payment2)
      expect(payments).to include(fabricated_payment3)
    end

    it 'does not list payments to non paid invoices' do
      invoice_item_attrs = [{
        name: 'Membership',
        description: 'You member, you pay',
        unit_cost: 100,
        count: 1,
      }, {
        name: 'Shirt',
        description: 'Good quality',
        unit_cost: 50,
        count: 1,
      }]

      fabricated_payment1 = fabricate_payment(50.0, Date.new(3.years.ago.year, 1, 1))
      fabricated_payment2 = fabricate_payment(50.0, Date.new(2.years.ago.year, 3, 20))
      fabricated_payment3 = fabricate_payment(50.0, Date.new(1.year.ago.year, 12, 31))

      fabricated_payment1.invoice.update(invoice_items_attributes: invoice_item_attrs)
      fabricated_payment2.invoice.update(invoice_items_attributes: [invoice_item_attrs.last])
      fabricated_payment3.invoice.update(invoice_items_attributes: [invoice_item_attrs.last])

      payments = described_class.new.of_fully_paid_invoices.instance_variable_get(:@payments)

      expect(payments.size).to eq(2)
      expect(payments).to_not include(fabricated_payment1)
      expect(payments).to include(fabricated_payment2)
      expect(payments).to include(fabricated_payment3)
    end
  end

  context 'having_invoice_item' do
    it 'returns matching payments' do
      invoice_item_attrs = [{
        name: 'Membership',
        description: 'You member, you pay',
        cost_center: 'Members',
        account: '01-12345-06',
        unit_cost: 100,
        count: 1,
      }, {
        name: 'Shirt',
        description: 'Good quality',
        cost_center: 'Merch',
        account: '10-987654-03',
        unit_cost: 50,
        count: 1,
      }, {
        name: 'Goodie',
        description: 'Something good',
        cost_center: 'Merch',
        account: '10-987654-03',
        unit_cost: 10,
        count: 42
      }]

      fabricated_payment1 = fabricate_payment(150.0, Date.new(3.years.ago.year, 1, 1))
      fabricated_payment2 = fabricate_payment(100.0, Date.new(2.years.ago.year, 3, 20))
      fabricated_payment3 = fabricate_payment(100.0, Date.new(1.years.ago.year, 3, 10))

      fabricated_payment1.invoice.update(invoice_items_attributes: invoice_item_attrs.take(2))
      fabricated_payment2.invoice.update(invoice_items_attributes: invoice_item_attrs.drop(1))
      fabricated_payment3.invoice.update(invoice_items_attributes: invoice_item_attrs.drop(2))

      result = described_class.new.having_invoice_item('Shirt', '10-987654-03', 'Merch').payments
      expect(result).to match_array([fabricated_payment1, fabricated_payment2])
    end
  end

  context 'grouped_by_invoice_items' do
    it 'allows invoice item totals to be summed up' do
      invoice_item_attrs = [{
        name: 'Membership',
        description: 'You member, you pay',
        cost_center: 'Members',
        account: '01-12345-06',
        unit_cost: 100,
        count: 1,
      }, {
        name: 'Shirt',
        description: 'Good quality',
        cost_center: 'Merch',
        account: '10-987654-03',
        unit_cost: 50,
        count: 1,
      }]

      fabricated_payment1 = fabricate_payment(150.0, Date.new(3.years.ago.year, 1, 1))
      fabricated_payment2 = fabricate_payment(100.0, Date.new(2.years.ago.year, 3, 20))

      fabricated_payment1.invoice.update(invoice_items_attributes: [invoice_item_attrs.first])
      fabricated_payment2.invoice.update(invoice_items_attributes: invoice_item_attrs)

      grouped_amounts = described_class.new.grouped_by_invoice_items.sum('count * unit_cost')

      expect(grouped_amounts.size).to eq(2)
      expect(grouped_amounts[['Membership', '01-12345-06', 'Members']]).to eq(200)
      expect(grouped_amounts[['Shirt', '10-987654-03', 'Merch']]).to eq(50)
    end
  end

  context 'in duration' do
    context 'from' do
      it 'lists only payments afterwards' do
        fabricated_payment1 = fabricate_payment(150.0, Date.new(Time.zone.today.year, 2, 21))
        fabricated_payment2 = fabricate_payment(100.0, Date.new(2.years.ago.year, 5, 20))

        payments = described_class.new.from(Date.new(1.year.ago.year, 3, 1)).instance_variable_get(:@payments)

        expect(payments).to include(fabricated_payment1)
        expect(payments).to_not include(fabricated_payment2)
      end
    end

    context 'to' do
      it 'lists only payments before' do
        fabricated_payment1 = fabricate_payment(150.0, Date.new(Time.zone.today.year, 2, 21))
        fabricated_payment2 = fabricate_payment(100.0, Date.new(2.years.ago.year, 5, 20))

        payments = described_class.new.to(Date.new(1.year.ago.year, 3, 1)).instance_variable_get(:@payments)

        expect(payments).to_not include(fabricated_payment1)
        expect(payments).to include(fabricated_payment2)
      end
    end

    context 'from and to' do
      it 'lists only payments in time range' do
        fabricated_payment1 = fabricate_payment(150.0, Date.new(Time.zone.today.year, 2, 21))
        fabricated_payment2 = fabricate_payment(100.0, Date.new(2.years.ago.year, 5, 20))
        fabricated_payment3 = fabricate_payment(120.0, Date.new(2.years.ago.year, 3, 10))

        payments = described_class.new.from(Date.new(2.years.ago.year, 3, 12)).to(Date.new(1.year.ago.year, 3, 1)).instance_variable_get(:@payments)

        expect(payments).to_not include(fabricated_payment1)
        expect(payments).to include(fabricated_payment2)
        expect(payments).to_not include(fabricated_payment3)
      end
    end
  end

  context 'median_amount' do
    context 'with no options' do
      it 'returns median for uneven list' do
        fabricate_payment(100.0, Date.new(3.years.ago.year, 1, 1))
        fabricate_payment(50.0, Date.new(1.year.ago.year, 12, 31))
        fabricate_payment(20.0, Date.new(1.year.ago.year, 12, 31))

        amount = described_class.new.in_last(3.years).in_layer(top_layer).of_person(bottom_member).median_amount

        expect(amount).to eq(50.0)
      end

      it 'returns median for even list' do
        fabricate_payment(100.0, Date.new(3.years.ago.year, 1, 1))
        fabricate_payment(50.0, Date.new(1.year.ago.year, 12, 31))
        fabricate_payment(20.0, Date.new(1.year.ago.year, 12, 31))
        fabricate_payment(100.0, Date.new(1.year.ago.year, 12, 31))
        fabricate_payment(2000.0, Date.new(1.year.ago.year, 12, 31))
        fabricate_payment(10.0, Date.new(1.year.ago.year, 12, 31))

        amount = described_class.new.in_last(3.years).in_layer(top_layer).of_person(bottom_member).median_amount

        expect(amount).to eq(75.0)
      end
    end

    context 'with increased_by option' do
      it 'returns increased amount for uneven list' do
        fabricate_payment(100.0, Date.new(3.years.ago.year, 1, 1))
        fabricate_payment(50.0, Date.new(1.year.ago.year, 12, 31))
        fabricate_payment(20.0, Date.new(1.year.ago.year, 12, 31))
        fabricate_payment(200.0, Date.new(3.years.ago.year, 1, 1))
        fabricate_payment(15000.0, Date.new(3.years.ago.year, 1, 1))

        amount = described_class.new.in_last(3.years).in_layer(top_layer).of_person(bottom_member).median_amount(increased_by: 10)

        # median is 100, times 10% (100 * 1.1 = 110)
        expect(amount).to eq(110.0)
      end

      it 'returns increased amount for even list' do
        fabricate_payment(110.0, Date.new(3.years.ago.year, 1, 1))
        fabricate_payment(50.0, Date.new(1.year.ago.year, 12, 31))
        fabricate_payment(20.0, Date.new(1.year.ago.year, 12, 31))
        fabricate_payment(90.0, Date.new(3.years.ago.year, 1, 1))
        fabricate_payment(15000.0, Date.new(3.years.ago.year, 1, 1))
        fabricate_payment(300.0, Date.new(3.years.ago.year, 1, 1))

        amount = described_class.new.in_last(3.years).in_layer(top_layer).of_person(bottom_member).median_amount(increased_by: 10)

        # median is 100 ((110 + 90) / 2), times 10% (100 * 1.1 = 110)
        expect(amount).to eq(110.0)
      end

      context 'previous_amount below 100' do
        it 'calculates increased amount and rounds up to 5' do
          fabricate_payment(100.0, Date.new(3.years.ago.year, 1, 1))
          fabricate_payment(50.0, Date.new(1.year.ago.year, 12, 31))
          fabricate_payment(20.0, Date.new(1.year.ago.year, 12, 31))
          fabricate_payment(300.0, Date.new(3.years.ago.year, 1, 1))

          amount = described_class.new.in_last(3.years).in_layer(top_layer).of_person(bottom_member).median_amount(increased_by: 10)

          # median is 75 ((50 + 100) / 2), times 10% (75 * 1.1 = 82.5), rounded up to next 5 = 85
          expect(amount).to eq(85.0)
        end
      end

      context 'previous_amount below 1000' do
        it 'calculates increased amount and rounds up to 10' do
          fabricate_payment(180.0, Date.new(3.years.ago.year, 1, 1))
          fabricate_payment(150.0, Date.new(3.years.ago.year, 1, 1))
          fabricate_payment(50.0, Date.new(1.year.ago.year, 12, 31))
          fabricate_payment(20.0, Date.new(1.year.ago.year, 12, 31))
          fabricate_payment(300.0, Date.new(3.years.ago.year, 1, 1))

          amount = described_class.new.in_last(3.years).in_layer(top_layer).of_person(bottom_member).median_amount(increased_by: 10)

          # median is 150, times 10% (150 * 1.1 = 165), rounded up to next 10 = 170
          expect(amount).to eq(170.0)
        end
      end

      context 'previous_amount above 1000' do
        it 'calculates increased amount and rounds up to 50' do
          fabricate_payment(1280.0, Date.new(3.years.ago.year, 1, 1))
          fabricate_payment(1250.0, Date.new(3.years.ago.year, 1, 1))
          fabricate_payment(150.0, Date.new(1.year.ago.year, 12, 31))
          fabricate_payment(120.0, Date.new(1.year.ago.year, 12, 31))
          fabricate_payment(1300.0, Date.new(3.years.ago.year, 1, 1))

          amount = described_class.new.in_last(3.years).in_layer(top_layer).of_person(bottom_member).median_amount(increased_by: 10)

          # median is 1250, times 10% (1250 * 1.1 = 1365), rounded up to next 50 = 1400
          expect(amount).to eq(1400.0)
        end
      end
    end
  end

  context 'payments_amount' do
    context 'with no options given' do
      it 'returns payment sum' do
        fabricate_payment(100.0, Date.new(3.years.ago.year, 1, 1))
        fabricate_payment(50.0, Date.new(1.year.ago.year, 12, 31))

        amount = described_class.new.in_last(1.year).in_layer(top_layer).of_person(bottom_member).payments_amount

        expect(amount).to eq(50)
      end
    end
  end

  private

  def fabricate_payment(amount, received_at = 1.year.ago)
    invoice = Fabricate(:invoice, due_at: 10.days.from_now, creator: top_leader, recipient: bottom_member, group: top_layer, state: :payed)
    Payment.create!(amount: amount, received_at: received_at, invoice: invoice)
  end

end
