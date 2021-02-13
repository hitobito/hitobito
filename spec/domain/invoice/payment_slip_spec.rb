# encoding: utf-8

#  Copyright (c) 2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Invoice::PaymentSlip do
  let(:invoice) { invoices(:invoice) }
  let(:subject) { Invoice::PaymentSlip.new(invoice) }

  %w(1236 1237 1230 1232 1239 1235 1238 1234 1231 1233).each_with_index do |number, index|
    it "#check_digit returns #{index} for #{number}" do
      expect(subject.check_digit(number)).to be(index)
    end
  end

  it "#esr_number is formatted group_id and index with check digit append" do
    expect(invoice.group_id).to eq 376803389
    expect(invoice.sequence_number).to eq "376803389-2"
    expect(subject.esr_number).to eq "00 00376 80338 90000 00000 00021"
  end

  it "#padded_number is 13 chars length zero padded group_id" do
    expect(subject.padded_number.size).to eq 13
    expect(subject.padded_number).to eq "0000376803389"
  end

  it "#padded_number cuts group id and prefixes participant_number_internal if set" do
    invoice.update(participant_number_internal: 999999)
    expect(subject.padded_number.size).to eq 13
    expect(subject.padded_number).to eq "9999993768033"
  end

  it "#esr_number calculates check digit based on padded group_id and index" do
    padded_group_id = subject.send(:zero_padded, invoice.group_id.to_s, 13)
    padded_index = subject.send(:zero_padded, "2", 13)
    expect(padded_group_id).to eq "0000376803389"
    expect(padded_index).to    eq "0000000000002"
    expect(subject.check_digit([padded_group_id, padded_index].join)).to eq 1
  end

  it "#code_line is includes amount if invoice_items are present" do
    expect(subject.code_line).to eq "0100000005353>000037680338900000000000021+ 376803389000004>"
    expect(invoice.total).to eq 5.35
  end

  it "#code_line formats iamount with precision 2" do
    invoice.update_columns(total: 5)
    expect(subject.code_line).to eq "0100000005007>000037680338900000000000021+ 376803389000004>"
  end

  it "#code_line is does not include amount if invoice_items are missing" do
    invoice.invoice_items.destroy_all
    expect(subject.code_line).to eq "042>000037680338900000000000021+ 376803389000004>"
  end
end
