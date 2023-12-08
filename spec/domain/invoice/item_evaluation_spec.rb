# frozen_string_literal: true

#  Copyright (c) 2022, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

# rubocop:disable Naming/VariableNumber,Layout/LineLength

describe Invoice::ItemEvaluation do
  let(:top_layer) { groups(:top_layer) }

  let(:top_leader) { people(:top_leader) }
  let(:bottom_member) { people(:bottom_member) }

  context 'fetch_evaluations' do

    it 'returns item totals of paid invoices' do
      invoice_attrs = {
        title: 'Membership',
        creator: top_leader,
        recipient: bottom_member,
        group: top_layer,
        invoice_items_attributes: [
          {
            name: 'Membership',
            unit_cost: 100,
            count: 1,
            vat_rate: 0,
            cost_center: 'Members',
            account: '01-23456-7'
          }, {
            name: 'Shirt',
            unit_cost: 30,
            count: 2,
            vat_rate: 5,
            cost_center: 'Merch',
            account: '08-76543-2'
          }
        ]
      }

      invoice_1 = Invoice.create(invoice_attrs)
      invoice_2 = Invoice.create(invoice_attrs)

      Payment.create(amount: invoice_1.recalculate, invoice: invoice_1, received_at: 2.months.ago)
      Payment.create(amount: invoice_2.recalculate, invoice: invoice_2, received_at: 3.months.ago)

      evaluations = described_class.new(top_layer, 1.year.ago, Time.zone.now + 1.month).fetch_evaluations
      expect(evaluations).to eq([{ name: 'Membership',
                                   amount_paid: 200, # 100 * 2
                                   count: 2,
                                   vat: 0,
                                   cost_center: 'Members',
                                   account: '01-23456-7',
                                   type: :by_article },
                                 { name: 'Shirt',
                                   amount_paid: 126, # 30 * 4 + 6
                                   count: 4,
                                   vat: 6, # 30 * 4 * 0.05 (5%)
                                   cost_center: 'Merch',
                                   account: '08-76543-2',
                                   type: :by_article }])
    end

    it 'ignores item totals of cancelled invoices' do
      invoice_attrs = {
        title: 'Membership',
        creator: top_leader,
        recipient: bottom_member,
        group: top_layer,
        invoice_items_attributes: [
          {
            name: 'Membership',
            unit_cost: 100,
            count: 1,
            vat_rate: 0,
            cost_center: 'Members',
            account: '01-23456-7'
          }, {
            name: 'Shirt',
            unit_cost: 30,
            count: 2,
            vat_rate: 5,
            cost_center: 'Merch',
            account: '08-76543-2'
          }
        ]
      }

      invoice_1 = Invoice.create(invoice_attrs)
      invoice_2 = Invoice.create(invoice_attrs)

      Payment.create(amount: invoice_1.recalculate, invoice: invoice_1, received_at: 2.months.ago)
      Payment.create(amount: invoice_2.recalculate, invoice: invoice_2, received_at: 3.months.ago)

      invoice_1.update!(state: :cancelled)

      evaluations = described_class.new(top_layer, 1.year.ago, Time.zone.now + 1.month).fetch_evaluations
      expect(evaluations).to eq([{ name: 'Membership',
                                   amount_paid: 100, # 100 * 1
                                   count: 1,
                                   vat: 0,
                                   cost_center: 'Members',
                                   account: '01-23456-7',
                                   type: :by_article },
                                 { name: 'Shirt',
                                   amount_paid: 63, # 30 * 2 + 3
                                   count: 2,
                                   vat: 3, # 30 * 2 * 0.05 (5%)
                                   cost_center: 'Merch',
                                   account: '08-76543-2',
                                   type: :by_article }])
    end

    it 'returns sum of deficit' do
      invoice_attrs = {
        title: 'Membership',
        creator: top_leader,
        recipient: bottom_member,
        group: top_layer,
        invoice_items_attributes: [
          {
            name: 'Membership',
            unit_cost: 100,
            count: 1,
            vat_rate: 0,
            cost_center: 'Members',
            account: '01-23456-7'
          }, {
            name: 'Shirt',
            unit_cost: 30,
            count: 2,
            vat_rate: 5,
            cost_center: 'Merch',
            account: '08-76543-2'
          }
        ]
      }

      invoice_1 = Invoice.create(invoice_attrs)
      invoice_2 = Invoice.create(invoice_attrs)
      invoice_3 = Invoice.create(invoice_attrs)

      Payment.create(amount: 100, invoice: invoice_1, received_at: 2.months.ago)
      Payment.create(amount: 100, invoice: invoice_2, received_at: 2.months.ago)
      Payment.create(amount: invoice_3.recalculate, invoice: invoice_3, received_at: 3.months.ago)

      evaluations = described_class.new(top_layer, 1.year.ago, Time.zone.now + 1.month).fetch_evaluations
      expect(evaluations).to eq([{ name: 'Membership',
                                   amount_paid: 100, # 1 fully paid invoice with count 1 and unit_cost 100
                                   count: 1,
                                   vat: 0,
                                   cost_center: 'Members',
                                   account: '01-23456-7',
                                   type: :by_article },
                                 { name: 'Shirt',
                                   amount_paid: 63, # 1 fully paid invoice with count 2 and unit_cost 30, vat 5%
                                   count: 2,
                                   vat: 3,
                                   cost_center: 'Merch',
                                   account: '08-76543-2',
                                   type: :by_article },
                                 { name: 'Teilzahlung',
                                   amount_paid: 200, # 2 payments with amount 100
                                   count: 2,
                                   vat: '',
                                   cost_center: '',
                                   account: '',
                                   type: :deficit }])
    end

    it 'returns sum of excess' do
      invoice_attrs = {
        title: 'Membership',
        creator: top_leader,
        recipient: bottom_member,
        group: top_layer,
        invoice_items_attributes: [
          {
            name: 'Membership',
            unit_cost: 100,
            count: 1,
            vat_rate: 0,
            cost_center: 'Members',
            account: '01-23456-7'
          }, {
            name: 'Shirt',
            unit_cost: 30,
            count: 2,
            vat_rate: 5,
            cost_center: 'Merch',
            account: '08-76543-2'
          }
        ]
      }

      invoice_1 = Invoice.create(invoice_attrs)
      invoice_2 = Invoice.create(invoice_attrs)

      Payment.create(amount: invoice_1.recalculate + 150, invoice: invoice_1, received_at: 2.months.ago)
      Payment.create(amount: invoice_2.recalculate + 100, invoice: invoice_2, received_at: 2.months.ago)

      evaluations = described_class.new(top_layer, 1.year.ago, Time.zone.now + 1.month).fetch_evaluations
      expect(evaluations).to eq([{ name: 'Membership',
                                   amount_paid: 200, # 100 * 2
                                   count: 2,
                                   vat: 0,
                                   cost_center: 'Members',
                                   account: '01-23456-7',
                                   type: :by_article },
                                 { name: 'Shirt',
                                   amount_paid: 126, # 30 * 4 + 6
                                   count: 4,
                                   vat: 6, # 30 * 4 * 0.05 (5%)
                                   cost_center: 'Merch',
                                   account: '08-76543-2',
                                   type: :by_article },
                                 { name: 'Überzahlung',
                                   amount_paid: 250, # 2 payments with excess amounts of 100 and 150
                                   count: '',
                                   vat: '',
                                   cost_center: '',
                                   account: '',
                                   type: :excess }])
    end

    it 'returns item totals of paid invoices if all payments are in daterange' do
      invoice_attrs = {
        title: 'Membership',
        creator: top_leader,
        recipient: bottom_member,
        group: top_layer,
        invoice_items_attributes: [
          {
            name: 'Membership',
            unit_cost: 100,
            count: 1,
            vat_rate: 0,
            cost_center: 'Members',
            account: '01-23456-7'
          }, {
            name: 'Shirt',
            unit_cost: 30,
            count: 2,
            vat_rate: 5,
            cost_center: 'Merch',
            account: '08-76543-2'
          }
        ]
      }

      invoice_1 = Invoice.create(invoice_attrs)

      Payment.create(amount: 100, invoice: invoice_1, received_at: 2.months.ago)
      Payment.create(amount: 63, invoice: invoice_1, received_at: 1.month.ago)

      evaluations = described_class.new(top_layer, 3.months.ago, Time.zone.now).fetch_evaluations
      expect(evaluations).to eq([{ name: 'Membership',
                                   amount_paid: 100,
                                   count: 1,
                                   vat: 0,
                                   cost_center: 'Members',
                                   account: '01-23456-7',
                                   type: :by_article},
                                 { name: 'Shirt',
                                   amount_paid: 63,
                                   count: 2,
                                   vat: 3,
                                   cost_center: 'Merch',
                                   account: '08-76543-2',
                                   type: :by_article }])
    end

    it 'returns sum of deficit if not all payments are in daterange' do
      invoice_attrs = {
        title: 'Membership',
        creator: top_leader,
        recipient: bottom_member,
        group: top_layer,
        invoice_items_attributes: [
          {
            name: 'Membership',
            unit_cost: 100,
            count: 1,
            vat_rate: 0,
            cost_center: 'Members',
            account: '01-23456-7'
          }, {
            name: 'Shirt',
            unit_cost: 30,
            count: 2,
            vat_rate: 5,
            cost_center: 'Merch',
            account: '08-76543-2'
          }
        ]
      }

      invoice_1 = Invoice.create(invoice_attrs)

      Payment.create(amount: 30, invoice: invoice_1, received_at: 3.months.ago)
      Payment.create(amount: 33, invoice: invoice_1, received_at: 2.months.ago)
      Payment.create(amount: 100, invoice: invoice_1, received_at: 1.month.ago)

      evaluations = described_class.new(top_layer, 2.months.ago, Time.zone.now).fetch_evaluations
      expect(evaluations).to eq([{ name: 'Teilzahlung',
                                   amount_paid: 133,
                                   count: 2,
                                   vat: '',
                                   cost_center: '',
                                   account: '',
                                   type: :deficit }])
    end
  end
end

# rubocop:enable Naming/VariableNumber,Layout/LineLength
