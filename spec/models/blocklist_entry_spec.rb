# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe BlocklistEntry do
  let(:legacy_hash) { Digest::MD5.hexdigest(".max.mustermann.1980-01-15 00:00:00") }
  let(:name_hash) { Digest::MD5.hexdigest(".max.mustermann") }
  let(:max_attrs) { {first_name: "Max", last_name: "Mustermann", birthday: "15.01.1980"} }
  let(:all_attrs) { %w[first_name last_name birthday] }

  it "calculates hash from manually entered attributes" do
    entry = described_class.create!(manual_person_attributes: max_attrs)

    expect(entry.blocked_hash).to eq legacy_hash
    expect(entry.reload.hashed_attrs).to eq %w[first_name last_name birthday]
  end

  it "calculates hash from given person" do
    person = Fabricate(:person, first_name: "Max", last_name: "Mustermann", birthday: "1980-01-15")
    entry = described_class.create!(person_id: person.id, manual_person_attributes: {first_name: "Other"})

    expect(entry.blocked_hash).to eq legacy_hash
  end

  it "creates additional entries without optional attributes" do
    creator = Fabricate(:person)

    expect do
      described_class.create!(manual_person_attributes: max_attrs, creator: creator)
    end.to change { described_class.count }.by(2)

    partial = described_class.find_by!(blocked_hash: name_hash)
    expect(partial.hashed_attrs).to eq %w[first_name last_name]
    expect(partial.creator).to eq creator
  end

  it "skips additional entries which already exist" do
    described_class.create!(manual_person_attributes: {first_name: "Max", last_name: "Mustermann"})

    expect do
      described_class.create!(manual_person_attributes: max_attrs)
    end.to change { described_class.count }.by(1)
  end

  it "accepts imported hash with attributes" do
    entry = described_class.create!(blocked_hash: legacy_hash, hashed_attrs: all_attrs)

    expect(entry.reload.blocked_hash).to eq legacy_hash
    expect(entry.hashed_attrs).to eq all_attrs
    expect(described_class.count).to eq 1
  end

  it "requires attributes for imported hash" do
    entry = described_class.new(blocked_hash: legacy_hash)

    expect(entry).not_to be_valid
    expect(entry.errors[:hashed_attrs]).to be_present
  end

  it "requires person or manual attributes if no hash is given" do
    entry = described_class.new(manual_person_attributes: {first_name: " "})

    expect(entry).not_to be_valid
    expect(entry.errors.full_messages)
      .to eq ["Hash kann nur berechnet werden, wenn eine Person gesucht oder Angaben erfasst werden"]
  end

  it "includes blank mandatory attributes" do
    entry = described_class.create!(manual_person_attributes: {first_name: "Max", birthday: "15.01.1980"})

    expect(entry.blocked_hash).to eq Digest::MD5.hexdigest(".max..1980-01-15 00:00:00")
    expect(entry.hashed_attrs).to eq %w[first_name last_name birthday]
  end

  it "is invalid if hash already exists" do
    described_class.create!(blocked_hash: legacy_hash, hashed_attrs: all_attrs)
    entry = described_class.new(manual_person_attributes: {first_name: "max", last_name: "mustermann",
                                                           birthday: "1980-01-15"})

    expect(entry).not_to be_valid
    expect(entry.errors[:base]).to be_present
  end

  it "accepts same hash for different attributes" do
    described_class.create!(blocked_hash: name_hash, hashed_attrs: %w[first_name company_name])
    entry = described_class.new(manual_person_attributes: {first_name: "Max", last_name: "Mustermann"})

    expect(entry).to be_valid
  end

  it "keeps entry when creator is destroyed" do
    creator = Fabricate(:person)
    entry = described_class.create!(blocked_hash: legacy_hash, hashed_attrs: all_attrs, creator: creator)
    creator.destroy!

    expect(entry.reload.creator_id).to eq creator.id
  end
end
