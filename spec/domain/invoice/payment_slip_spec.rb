# encoding: utf-8

#  Copyright (c) 2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Invoice::PaymentSlip do
  let(:group)          { groups(:top_layer) }
  let(:person)         { people(:top_leader) }

  context 'check digit' do
    let(:esr_number) { Invoice::PaymentSlip.new }

    it 'calculates' do
      numbers = ['1236', '1237', '1230', '1232', '1239', '1235', '1238', '1234', '1231', '1233']
      numbers.each_with_index do |nr, i|
        expect(esr_number.check_digit(nr)).to be(i)
      end
    end
  end

  context 'esr number' do
    it 'creates and formats esr number based on invoice and check digit' do
      invoice = create_invoice
      esr_number = invoice.sequence_number.split('-').map { |nr| format('%013d', nr.to_i) }.join
      check_digit = Invoice::PaymentSlip.new.check_digit(esr_number)
      esr_number = "#{esr_number}#{check_digit}"
      esr_number = esr_number.reverse.gsub(/(.{5})/, '\1 ').reverse

      expect(invoice.esr_number).to eq(esr_number)
    end
  end

  context 'code line' do
    it 'creates code line with amount' do
      invoice = create_invoice
      invoice.invoice_items.create
      invoice.total = 32.32
      code_line = Invoice::PaymentSlip.new(invoice).code_line

      expected_code_line = "0100000032320>#{invoice.esr_number.delete(' ')}+ 100053185>"
      expect(code_line).to eq(expected_code_line)
    end

    it 'creates code line without amount' do
      invoice = create_invoice
      code_line = Invoice::PaymentSlip.new(invoice).code_line

      expected_code_line = "042>#{invoice.esr_number.delete(' ')}+ 100053185>"
      expect(code_line).to eq(expected_code_line)
    end
  end

  private

  def create_invoice(attrs = {})
    Invoice.create!(attrs.merge(title: 'invoice', group: group, recipient: person))
  end
end
