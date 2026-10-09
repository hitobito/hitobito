# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe BlocklistEntry do
  let(:legacy_hash) { Digest::MD5.hexdigest(".max.mustermann.1980-01-15 00:00:00") }

  it "calculates hash from manually entered attributes" do
    entry = described_class.create!(manual_person_attributes: {first_name: "Max", last_name: "Mustermann",
                                                               birthday: "15.01.1980"})

    expect(entry.blocked_hash).to eq legacy_hash
  end

  it "calculates hash from given person" do
    person = Fabricate(:person, first_name: "Max", last_name: "Mustermann", birthday: "1980-01-15")
    entry = described_class.create!(person_id: person.id, manual_person_attributes: {first_name: "Other"})

    expect(entry.blocked_hash).to eq legacy_hash
  end

  it "accepts imported hash without attributes" do
    entry = described_class.create!(blocked_hash: legacy_hash)

    expect(entry.reload.blocked_hash).to eq legacy_hash
  end

  it "requires person or manual attributes if no hash is given" do
    entry = described_class.new(manual_person_attributes: {first_name: " "})

    expect(entry).not_to be_valid
    expect(entry.errors[:base]).to eq ["Bitte eine Person suchen oder Angaben erfassen."]
  end

  it "is invalid if hash already exists" do
    described_class.create!(blocked_hash: legacy_hash)
    entry = described_class.new(manual_person_attributes: {first_name: "max", last_name: "mustermann",
                                                           birthday: "1980-01-15"})

    expect(entry).not_to be_valid
    expect(entry.errors[:base]).to be_present
  end

  it "keeps entry when creator is destroyed" do
    creator = Fabricate(:person)
    entry = described_class.create!(blocked_hash: legacy_hash, creator: creator)
    creator.destroy!

    expect(entry.reload.creator_id).to eq creator.id
  end
end
