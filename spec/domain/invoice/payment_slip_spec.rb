#  Copyright (c) 2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Invoice::PaymentSlip do
  let(:invoice) { invoices(:invoice) }
  let(:subject) { Invoice::PaymentSlip.new(invoice) }

  %w[1236 1237 1230 1232 1239 1235 1238 1234 1231 1233].each_with_index do |number, index|
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

  it "#esr_number calculates check digit based on padded group_id and index" do
    padded_group_id = subject.send(:zero_padded, invoice.group_id.to_s, 13)
    padded_index = subject.send(:zero_padded, "2", 13)
    expect(padded_group_id).to eq "0000376803389"
    expect(padded_index).to eq "0000000000002"
    expect(subject.check_digit([padded_group_id, padded_index].join)).to eq 1
  end

  context "with reference_prefix" do
    before { allow(invoice).to receive(:group_id).and_return(12) }

    it "returns value of esr_number with prefix" do
      invoice.invoice_config.update!(reference_prefix: 1234567)
      expect(subject.esr_number).to eq "12 34567 00001 20000 00000 00028"
    end

    it "returns value of esr_number with prefix completed with 0 when prefix is only 5 characters long" do
      invoice.invoice_config.update!(reference_prefix: 12345)
      expect(subject.esr_number).to eq "12 34500 00001 20000 00000 00024"
    end

    it "does not use prefix when qr_without_qr_iban?" do
      allow(invoice).to receive(:qr_without_qr_iban?).and_return(true)
      invoice.invoice_config.update!(reference_prefix: 1234567)
      expect(subject.esr_number).to eq "00 00000 00001 20000 00000 00023"
    end
  end

  context "errors" do
    before { allow(invoice).to receive(:group_id).and_return(1000000) }

    it "raises when prefix overwrites any numbers other than zero" do
      invoice.invoice_config.update!(reference_prefix: 1234567)
      expect { subject.esr_number }.to raise_error "HighlyUnlikelyError: Prefixing the reference number is not possible for this invoice, sequence number (group_id, invoice count) is too long. This error will only occur for invoices created in groups with an id higher than 999'999"
    end
  end

  it "#code_line is includes amount if invoice_items are present" do
    expect(subject.code_line).to eq "0100000005353>000037680338900000000000021+ 376803389000004>"
    expect(invoice.total).to eq 5.35
  end

  it "#code_line does not include amount if total is hidden" do
    invoice.hide_total = true
    expect(subject.code_line).to eq "011>000037680338900000000000021+ 376803389000004>"
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
