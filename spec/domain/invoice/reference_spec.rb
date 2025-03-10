# frozen_string_literal: true

#  Copyright (c) 2012-2025, Hitobito AG. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Invoice::Reference do
  describe "reference number" do
    let(:invoice) { invoices(:invoice) }

    before { invoice.update!(esr_number: "00 00000 80338 90000 00000 00021") }

    context "without reference_prefix" do
      it "returns value of esr_number without whitespaces" do
        expect(described_class.create(invoice)).to eq "000000080338900000000000021"
      end
    end

    context "with reference_prefix" do
      it "returns value of esr_number with prefix" do
        invoice.invoice_config.update!(reference_prefix: 1234567)
        expect(described_class.create(invoice)).to eq "123456780338900000000000021"
      end

      it "returns value of esr_number with prefix completed with 0 when prefix is only 5 characters long" do
        invoice.invoice_config.update!(reference_prefix: 12345)
        expect(described_class.create(invoice)).to eq "123450080338900000000000021"
      end
    end

    context "errors" do
      it "raises when prefix overwrites any numbers other than zero" do
        invoice.update!(esr_number: "00 00376 80338 90000 00000 00021")
        invoice.invoice_config.update!(reference_prefix: 1234567)
        expect { described_class.create(invoice) }.to raise_error "HighlyUnlikelyError: Prefixing the reference number is not possible for this invoice, sequence number (group_id, invoice count) is too long. This error will only occur for invoices created in groups with an id higher than 999'999"
      end
    end
  end
end
