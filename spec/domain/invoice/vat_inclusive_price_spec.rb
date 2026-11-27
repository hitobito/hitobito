# frozen_string_literal: true

#  Copyright (c) 2026, florist.ch. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Invoice::VatInclusivePrice do
  describe ".net" do
    it "removes vat and rounds to cents" do
      expect(described_class.net("10.00", "8.1")).to eq BigDecimal("9.25")
    end

    it "keeps price without vat rate" do
      expect(described_class.net("10.00", "")).to eq BigDecimal("10.00")
      expect(described_class.net("10.00", nil)).to eq BigDecimal("10.00")
    end

    it "keeps blank and invalid prices for validation" do
      expect(described_class.net("", "8.1")).to eq ""
      expect(described_class.net(nil, "8.1")).to be_nil
      expect(described_class.net("abc", "8.1")).to eq "abc"
    end
  end

  describe ".gross" do
    it "adds vat and rounds to cents" do
      expect(described_class.gross(BigDecimal("9.25"), BigDecimal("8.1"))).to eq BigDecimal("10.00")
    end

    it "keeps price without vat rate" do
      expect(described_class.gross(BigDecimal("9.25"), nil)).to eq BigDecimal("9.25")
    end

    it "keeps missing price" do
      expect(described_class.gross(nil, BigDecimal("8.1"))).to be_nil
    end
  end
end
