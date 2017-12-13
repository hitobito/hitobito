# encoding: utf-8

#  Copyright (c) 2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Invoice::EsrNumber do
  let(:group)          { groups(:top_layer) }
  let(:person)         { people(:top_leader) }

  context 'check digit' do
    let(:esr_number) { Invoice::EsrNumber.new }

    it 'calculates' do
      numbers = ['1236', '1237', '1230', '1232', '1239', '1235', '1238', '1234', '1231', '1233']
      numbers.each_with_index do |nr, i|
        expect(esr_number.send(:check_digit, nr)).to be(i)
      end
    end
  end

  context 'esr number' do
    it 'creates and formats esr number based on sequence_number and check digit' do
      invoice = create_invoice
      esr_number = invoice.sequence_number.split('-').map { |nr| format('%013d', nr.to_i) }.join
      check_digit = Invoice::EsrNumber.new.send(:check_digit, esr_number)
      esr_number = "#{esr_number}#{check_digit}"
      esr_number = esr_number.reverse.gsub(/(.{5})/, '\1 ').reverse

      expect(invoice.esr_number).to eq(esr_number)
    end
  end

  private

  def create_invoice(attrs = {})
    Invoice.create!(attrs.merge(title: 'invoice', group: group, recipient: person))
  end
end
