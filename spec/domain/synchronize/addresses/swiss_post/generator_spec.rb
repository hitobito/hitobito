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

  it "generates Windows-1512 encoded data" do
    expect(generator.generate.encoding.to_s).to eq "Windows-1252"
  end

  it "generates expected headers" do
    expect(result.headers).to eq [
      "KDNR (QSTAT)",
      "Firma",
      "Vorname",
      "Nachname",
      "c/o",
      "Strasse",
      "Hausnummer",
      "Postfach",
      "PLZ",
      "Ort"
    ]
  end

  it "generates 2 entries" do
    expect(result.entries).to have(2).items
    expect(result[0]["KDNR (QSTAT)"]).to eq(bottom_member.id.to_s)
    expect(result[1]["KDNR (QSTAT)"]).to eq(top_leader.id.to_s)
  end

  it "populates fields accordingly" do
    expect(result[0].to_h).to eq({
      "KDNR (QSTAT)" => bottom_member.id.to_s,
      "Firma" => nil,
      "Vorname" => "Bottom",
      "Nachname" => "Member",
      "c/o" => nil,
      "Strasse" => "Greatstreet",
      "Hausnummer" => "345",
      "Postfach" => nil,
      "PLZ" => "3456",
      "Ort" => "Greattown"
    })
  end

  it "ignores, logs and tags person containing non encodable data" do
    bottom_member.update!(first_name: "fist 👊")
    expect do
      expect(result.entries).to have(1).items
    end.to change { HitobitoLogEntry.count }.by(1)
      .and change { bottom_member.tags.count }.by(1)

    expect(result[0]["KDNR (QSTAT)"]).to eq(top_leader.id.to_s)

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

  it "populates Firma with company name only if company flag is set" do
    bottom_member.update!(company: true, company_name: "Dummy, Inc.")
    top_leader.update!(company: false, company_name: "Dummy, Inc.")
    expect(result[0]["Firma"]).to eq "Dummy, Inc."
    expect(result[1]["Firma"]).to be_nil
  end
end
