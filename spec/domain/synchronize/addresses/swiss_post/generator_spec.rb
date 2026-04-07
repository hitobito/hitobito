# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe Synchronize::Addresses::SwissPost::Generator do
  let(:scope) { Person.joins(:roles) }
  let(:bottom_member) { people(:bottom_member) }
  let(:top_leader) { people(:top_leader) }
  let(:generator) { described_class.new(scope, invalid_tag) }
  let(:invalid_tag) { PersonTags::Validation.post_address_check_invalid }

  subject(:result) { CSV.parse(generator.generate, col_sep: "\t", row_sep: "\r\n", headers: true) }

  it "generates expected headers" do
    expect(result.headers).to eq ["CustomID_01_in", "Company_in", "Prename_in", "Prename2_in", "Name_in",
      "MaidenName_in", "AddressAddition_in", "CoAddress_in", "StreetName_in", "HouseNo_in", "HouseNoAddition_in",
      "Floor_in", "ZIPCode_in", "ZIPAddition_in", "TownName_in", "Canton_in", "CountryCode_in",
      "PoBoxTerm_in", "PoBoxNo_in", "PoBoxZIP_in", "PoBoxZIPAddition_in", "PoBoxTownName_in",
      "PassThrough_01", "PassThrough_02", "PassThrough_03", "PassThrough_04", "PassThrough_05", "PassThrough_06",
      "PassThrough_07", "PassThrough_08", "PassThrough_09", "PassThrough_10"]
  end

  it "generates 2 entries" do
    expect(result.entries).to have(2).items
    expect(result[0]["Prename_in"]).to eq(bottom_member.first_name)
    expect(result[1]["Prename_in"]).to eq(top_leader.first_name)
  end

  it "populates fields accordingly" do
    expect(result[0].to_h.symbolize_keys).to eq(
      {
        CustomID_01_in: nil,
        Company_in: nil,
        Prename_in: "Bottom",
        Prename2_in: nil,
        Name_in: "Member",
        MaidenName_in: nil,
        AddressAddition_in: nil,
        CoAddress_in: nil,
        StreetName_in: "Greatstreet",
        HouseNo_in: "345",
        HouseNoAddition_in: nil,
        Floor_in: nil,
        ZIPCode_in: "3456",
        ZIPAddition_in: nil,
        TownName_in: "Greattown",
        Canton_in: nil,
        CountryCode_in: "CH",
        PoBoxTerm_in: nil,
        PoBoxNo_in: nil,
        PoBoxZIP_in: nil,
        PoBoxZIPAddition_in: nil,
        PoBoxTownName_in: nil,
        PassThrough_01: bottom_member.id.to_s,
        PassThrough_02: nil,
        PassThrough_03: nil,
        PassThrough_04: nil,
        PassThrough_05: nil,
        PassThrough_06: nil,
        PassThrough_07: nil,
        PassThrough_08: nil,
        PassThrough_09: nil,
        PassThrough_10: nil
      }
    )
  end

  it "populates Firma with company name only if company flag is set" do
    bottom_member.update!(company: true, company_name: "Dummy, Inc.")
    top_leader.update!(company: false, company_name: "Dummy, Inc.")
    expect(result[0]["Company_in"]).to eq "Dummy, Inc."
    expect(result[1]["Company_in"]).to be_nil
  end

  [
    ["", nil, nil],
    ["123", "123", nil],
    ["123a", "123", "a"],
    ["123A", "123", "A"],
    ["123 a", "123", "a"],
    ["123 a", "123", "a"],
    ["123 ab", "123", "ab"]
  ].each do |housenumber, number, addition|
    it "converts housenumber #{housenumber} to #{number} with #{addition}" do
      bottom_member.update!(housenumber:)
      expect(result[0]["HouseNo_in"]).to eq number
      expect(result[0]["HouseNoAddition_in"]).to eq addition
    end
  end

  describe "customizing encoding" do
    before { allow(Synchronize::Addresses::SwissPost::Config).to receive(:encoding).and_return("Windows-1252") }

    it "generates Windows-1512 encoded data" do
      expect(generator.generate.encoding.to_s).to eq "Windows-1252"
    end

    it "ignores, logs and tags person containing non encodable data" do
      bottom_member.update!(first_name: "fist 👊")
      expect do
        expect(result.entries).to have(1).items
      end.to change { HitobitoLogEntry.count }.by(1)
        .and change { bottom_member.tags.count }.by(1)

      expect(result[0]["Prename_in"]).to eq(top_leader.first_name)

      expect(HitobitoLogEntry.last.level).to eq "warn"
      expect(HitobitoLogEntry.last.category).to eq "cleanup"
      expect(HitobitoLogEntry.last.message).to eq "Die Personendaten zu fist 👊 Member(382461928) " \
        "konnten nicht übertragen werden"

      tagging = bottom_member.reload.taggings.first
      expect(tagging.tag.to_s).to eq "category_validation:post_address_check_invalid"
      expect(tagging.hitobito_tooltip).to eq "Die Personendaten zu fist 👊 Member(382461928) " \
        "konnten nicht übertragen werden"
    end

    it "does not duplicate existing tag" do
      bottom_member.update!(first_name: "fist 👊")
      bottom_member.taggings.create!(tag: PersonTags::Validation.post_address_check_invalid, context: :tags)
      expect do
        expect(result.entries).to have(1).items
      end.to change { HitobitoLogEntry.count }.by(1)
        .and not_change { bottom_member.reload.tags.count }
    end
  end
end
