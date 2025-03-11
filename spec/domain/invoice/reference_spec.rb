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
  end
end
