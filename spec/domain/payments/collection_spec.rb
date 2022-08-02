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

  context 'of_fully_payed_invoices' do
    it 'lists payments to fully payed invoices' do
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

      payments = described_class.new.of_fully_payed_invoices.instance_variable_get(:@payments)

      expect(payments.size).to eq(3)
      expect(payments).to include(fabricated_payment1)
      expect(payments).to include(fabricated_payment2)
      expect(payments).to include(fabricated_payment3)
    end

    it 'does not list payments to non payed invoices' do
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

      payments = described_class.new.of_fully_payed_invoices.instance_variable_get(:@payments)

      expect(payments.size).to eq(2)
      expect(payments).to_not include(fabricated_payment1)
      expect(payments).to include(fabricated_payment2)
      expect(payments).to include(fabricated_payment3)
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

  context 'previous_amount' do
    context 'with no options given' do
      it 'returns payment sum' do
        fabricate_payment(100.0, Date.new(3.years.ago.year, 1, 1))
        fabricate_payment(50.0, Date.new(1.year.ago.year, 12, 31))

        amount = described_class.new.in_last(1.year).in_layer(top_layer).of_person(bottom_member).previous_amount

        expect(amount).to eq(50)
      end
    end

    context 'previous_amount below 100' do
      it 'calculates increased amount' do
        fabricate_payment(50.0)

        increased_amount = described_class.new.in_last(1.year).in_layer(top_layer).of_person(bottom_member).previous_amount(increased_by: 10)

        expect(increased_amount).to eq(55)
      end

      it 'calculates increased amount and rounds up to 5' do
        fabricate_payment(50)

        increased_amount = described_class.new.in_last(1.year).in_layer(top_layer).of_person(bottom_member).previous_amount(increased_by: 5)

        # 52.5 gets round up to 55
        expect(increased_amount).to eq(55)
      end

      it 'calculates increased amount and rounds down to 5' do
        fabricate_payment(50)

        increased_amount = described_class.new.in_last(1.year).in_layer(top_layer).of_person(bottom_member).previous_amount(increased_by: 4)

        # 52 gets round down to 50
        expect(increased_amount).to eq(50)
      end
    end

    context 'previous_amount below 1000' do
      it 'calculates increased amount' do
        fabricate_payment(100)

        increased_amount = described_class.new.in_last(1.year).in_layer(top_layer).of_person(bottom_member).previous_amount(increased_by: 10)

        expect(increased_amount).to eq(110)
      end

      it 'calculates increased amount and rounds up to 10' do
        fabricate_payment(100)

        increased_amount = described_class.new.in_last(1.year).in_layer(top_layer).of_person(bottom_member).previous_amount(increased_by: 5)

        # 105 gets round up to 110
        expect(increased_amount).to eq(110)
      end

      it 'calculates increased amount and rounds down to 10' do
        fabricate_payment(100)

        increased_amount = described_class.new.in_last(1.year).in_layer(top_layer).of_person(bottom_member).previous_amount(increased_by: 4)

        # 104 gets round down to 100
        expect(increased_amount).to eq(100)
      end
    end

    context 'previous_amount above 1000' do
      it 'calculates increased amount' do
        fabricate_payment(1000)

        increased_amount = described_class.new.in_last(1.year).in_layer(top_layer).of_person(bottom_member).previous_amount(increased_by: 5)

        expect(increased_amount).to eq(1050)
      end

      it 'calculates increased amount and rounds up to 50' do
        fabricate_payment(1000)

        increased_amount = described_class.new.in_last(1.year).in_layer(top_layer).of_person(bottom_member).previous_amount(increased_by: 13)

        # 1130 gets round up to 1150
        expect(increased_amount).to eq(1150)
      end

      it 'calculates increased amount and rounds down to 50' do
        fabricate_payment(1000)

        increased_amount = described_class.new.in_last(1.year).in_layer(top_layer).of_person(bottom_member).previous_amount(increased_by: 12)

        # 1120 gets round down to 1100
        expect(increased_amount).to eq(1100)
      end
    end
  end

  private

  def fabricate_payment(amount, received_at = 1.year.ago)
    invoice = Fabricate(:invoice, due_at: 10.days.from_now, creator: top_leader, recipient: bottom_member, group: top_layer, state: :payed)
    Payment.create!(amount: amount, received_at: received_at, invoice: invoice)
  end

end
