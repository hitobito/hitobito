# encoding: utf-8

#  Copyright (c) 2017-2019, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
# == Schema Information
#
# Table name: invoices
#
#  id                          :integer          not null, primary key
#  account_number              :string(255)
#  address                     :text(16777215)
#  beneficiary                 :text(16777215)
#  currency                    :string(255)      default("CHF"), not null
#  description                 :text(16777215)
#  due_at                      :date
#  esr_number                  :string(255)      not null
#  iban                        :string(255)
#  issued_at                   :date
#  participant_number          :string(255)
#  participant_number_internal :string(255)
#  payee                       :text(16777215)
#  payment_information         :text(16777215)
#  payment_purpose             :text(16777215)
#  payment_slip                :string(255)      default("ch_es"), not null
#  recipient_address           :text(16777215)
#  recipient_email             :string(255)
#  reference                   :string(255)      not null
#  sent_at                     :date
#  sequence_number             :string(255)      not null
#  state                       :string(255)      default("draft"), not null
#  title                       :string(255)      not null
#  total                       :decimal(12, 2)
#  vat_number                  :string(255)
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  creator_id                  :integer
#  group_id                    :integer          not null
#  invoice_list_id             :bigint
#  recipient_id                :integer
#
# Indexes
#
#  index_invoices_on_esr_number       (esr_number)
#  index_invoices_on_group_id         (group_id)
#  index_invoices_on_invoice_list_id  (invoice_list_id)
#  index_invoices_on_recipient_id     (recipient_id)
#  index_invoices_on_sequence_number  (sequence_number)
#

require 'spec_helper'


describe InvoiceSerializer do
  let(:top_leader) { people(:top_leader) }
  let(:invoice)    { invoices(:invoice) }
  let(:controller) { double().as_null_object }
  let(:serializer) { InvoiceSerializer.new(invoice, controller: controller)}
  let(:hash)       { serializer.to_hash.with_indifferent_access }

  subject { hash[:invoices].first }

  context 'invoice properties' do

    it 'includes all keys' do
      keys = [:title,
              :sequence_number,
              :state,
              :esr_number,
              :description,
              :recipient_email,
              :recipient_address,
              :sent_at,
              :due_at,
              :total,
              :created_at,
              :updated_at,
              :account_number,
              :address,
              :issued_at,
              :iban,
              :payment_purpose,
              :payment_information,
              :beneficiary,
              :payee,
              :participant_number,
              :vat_number]
      keys.each do |key|
        is_expected.to have_key(key)
      end
      expect(subject[:state].to_s).to eq 'draft'
      expect(subject[:total].to_s).to eq '5.35'
      expect(subject[:sequence_number].to_s).to eq invoice.sequence_number
    end

    it 'includes group link' do
      expect(hash[:linked][:groups]).to have(1).item
      expect(hash[:linked][:groups].first[:id]).to eq invoice.group_id.to_s
      expect(hash[:links]).to have_key('invoices.group')
    end

    it 'includes recipient and creator id and links' do
      invoice.update(creator: top_leader)
      expect(subject[:links][:creator]).to eq top_leader.id.to_s
      expect(subject[:links][:recipient]).to eq top_leader.id.to_s
      expect(hash[:links]).to have_key('invoices.creator')
      expect(hash[:links]).to have_key('invoices.recipient')
    end

  end

  context 'invoice items' do
    it 'includes ids in invoice' do
      expect(subject[:links][:invoice_items]).to have(2).items
    end

    it 'invoices keys in links' do
      keys = [:name,
              :description,
              :vat_rate,
              :unit_cost,
              :count,
              :cost_center,
              :account]

      keys.each do |key|
        expect(hash[:linked][:invoice_items].first).to have_key(key)
      end
    end
  end

  context 'payments' do
    before do
      invoice.payments.create!(amount: 10, received_at: Date.today)
    end

    it 'includes ids in invoice' do
      expect(subject[:links][:payments]).to have(1).items
    end

    it 'invoices values in links' do
      keys = [:amount, :received_at]

      keys.each do |key|
        expect(hash[:linked][:payments].first).to have_key(key)
      end
    end
  end

  context 'payment_reminders' do
    let(:invoice) { invoices(:sent) }
    before do
      invoice.payment_reminders.create!(due_at: 30.days.from_now, level: 1)
    end

    it 'includes ids in invoice' do
      expect(subject[:links][:payment_reminders]).to have(1).items
    end

    it 'invoices values in links' do
      keys = [:due_at,
              :created_at,
              :updated_at,
              :title,
              :text,
              :level]


      keys.each do |key|
        expect(hash[:linked][:payment_reminders].first).to have_key(key)
      end
    end
  end
end
