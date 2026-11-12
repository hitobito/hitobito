# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe PostalAddress::Printed do
  let(:attrs) do
    {
      names: ["Muster AG", "Hans Muster"],
      care_of: "c/o Treuhand Meier",
      addition: "Chalet Edelweiss",
      street: "Bahnhofstrasse",
      housenumber: "4",
      postbox: nil,
      zip_code: "3011",
      town: "Bern",
      country: "CH"
    }
  end

  def lines(**overrides) = described_class.new(**attrs, **overrides).lines

  it "keeps addresses with 6 lines unchanged" do
    expect(lines).to eq [
      "Muster AG", "Hans Muster", "c/o Treuhand Meier", "Chalet Edelweiss",
      "Bahnhofstrasse 4", "3011 Bern"
    ]
  end

  it "omits blank lines" do
    expect(lines(names: ["Hans Muster", ""], care_of: "", addition: nil, street: " ", housenumber: nil))
      .to eq ["Hans Muster", "3011 Bern"]
  end

  it "renders street without housenumber" do
    expect(lines(care_of: nil, addition: nil, housenumber: " ")).to include "Bahnhofstrasse"
  end

  context "country" do
    it "omits domestic country" do
      expect(lines(care_of: nil, addition: nil).last).to eq "3011 Bern"
    end

    it "omits blank country" do
      expect(lines(care_of: nil, addition: nil, country: nil).last).to eq "3011 Bern"
    end

    it "renders foreign country as upper case name on last line" do
      expect(lines(care_of: nil, addition: nil, zip_code: "79539", town: "Lörrach", country: "DE"))
        .to eq ["Muster AG", "Hans Muster", "Bahnhofstrasse 4", "79539 Lörrach", "DEUTSCHLAND"]
    end
  end

  it "appends address addition to care of line" do
    expect(lines(country: "DE")).to eq [
      "Muster AG", "Hans Muster", "c/o Treuhand Meier, Chalet Edelweiss",
      "Bahnhofstrasse 4", "3011 Bern", "DEUTSCHLAND"
    ]
  end

  it "omits street if postbox is present and still too many lines" do
    expect(lines(postbox: "Postfach", country: "DE")).to eq [
      "Muster AG", "Hans Muster", "c/o Treuhand Meier, Chalet Edelweiss",
      "Postfach", "3011 Bern", "DEUTSCHLAND"
    ]
  end

  it "keeps street if postbox is present but line count fits after appending addition" do
    expect(lines(postbox: "Postfach")).to eq [
      "Muster AG", "Hans Muster", "c/o Treuhand Meier, Chalet Edelweiss",
      "Bahnhofstrasse 4", "Postfach", "3011 Bern"
    ]
  end

  it "keeps address addition on its own line without care of" do
    expect(lines(care_of: nil, postbox: "Postfach", country: "DE")).to eq [
      "Muster AG", "Hans Muster", "Chalet Edelweiss", "Postfach", "3011 Bern", "DEUTSCHLAND"
    ]
  end

  it "prints salutation first and counts it as line" do
    expect(lines(salutation: "Herr")).to eq [
      "Herr", "Muster AG", "Hans Muster", "c/o Treuhand Meier, Chalet Edelweiss",
      "Bahnhofstrasse 4", "3011 Bern"
    ]
  end

  context "names spanning several lines" do
    let(:names) { ["John Doe\nJane Foo"] }

    it "counts and prints each name on its own line" do
      expect(lines(names:, addition: nil)).to eq [
        "John Doe", "Jane Foo", "c/o Treuhand Meier", "Bahnhofstrasse 4", "3011 Bern"
      ]
    end

    it "joins names on one line if still too many lines" do
      expect(lines(names:, postbox: "Postfach", country: "DE")).to eq [
        "John Doe, Jane Foo", "c/o Treuhand Meier, Chalet Edelweiss", "Bahnhofstrasse 4",
        "Postfach", "3011 Bern", "DEUTSCHLAND"
      ]
    end
  end

  describe "#fits?" do
    it "is true if reductions reach the line limit" do
      expect(described_class.new(**attrs, postbox: "Postfach", country: "DE")).to be_fits
    end

    it "is false if too many lines remain after reductions" do
      address = described_class.new(**attrs, names: ["Hansi", "Muster AG", "Hans Muster"],
        country: "DE")
      expect(address).not_to be_fits
    end
  end
end
