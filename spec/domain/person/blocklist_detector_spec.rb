# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Person::BlocklistDetector do
  let(:person) { Person.new(first_name: "Max", last_name: "Mustermann", birthday: "1980-01-15") }
  let(:full_hash) { Digest::MD5.hexdigest(".max.mustermann.1980-01-15 00:00:00") }
  let(:name_hash) { Digest::MD5.hexdigest(".max.mustermann") }

  subject(:detector) { described_class.new(person) }

  def self.with_hash_attrs(mandatory, optional)
    around do |example|
      original = [described_class.hash_attrs, described_class.optional_hash_attrs]
      described_class.hash_attrs = mandatory
      described_class.optional_hash_attrs = optional
      example.run
    ensure
      described_class.hash_attrs, described_class.optional_hash_attrs = original
    end
  end

  describe "#blocked_hash" do
    it "is compatible with the hashes of the legacy system" do
      expect(detector.blocked_hash).to eq full_hash
    end

    it "ignores surrounding whitespace and case" do
      person.first_name = "  MAX "
      person.last_name = "MusterMann\t"

      expect(detector.blocked_hash).to eq full_hash
    end

    it "skips blank optional attributes" do
      person.birthday = nil

      expect(detector.blocked_hash).to eq name_hash
    end

    it "replaces dots in names" do
      person.first_name = "J.R."
      person.last_name = "St. Mustermann"

      expect(detector.blocked_hash).to eq Digest::MD5.hexdigest(".j_r_.st_ mustermann.1980-01-15 00:00:00")
    end

    it "includes blank mandatory attributes" do
      person.last_name = " "

      expect(detector.blocked_hash).to eq Digest::MD5.hexdigest(".max..1980-01-15 00:00:00")
    end

    it "is nil if all attributes are blank" do
      expect(described_class.new(Person.new).blocked_hash).to be_nil
    end
  end

  describe "#hashed_attrs" do
    it "contains mandatory and present optional attributes" do
      expect(detector.hashed_attrs).to eq [:first_name, :last_name, :birthday]
    end

    it "skips blank optional attributes" do
      person.birthday = nil

      expect(detector.hashed_attrs).to eq [:first_name, :last_name]
    end
  end

  describe "#all_blocked_hashes" do
    it "contains hashes with and without each present optional attribute" do
      expect(detector.all_blocked_hashes).to eq(
        [:first_name, :last_name] => name_hash,
        [:first_name, :last_name, :birthday] => full_hash
      )
    end

    context "with multiple optional attributes" do
      with_hash_attrs([:last_name], [:first_name, :birthday])

      it "contains all combinations in configured order" do
        expect(detector.all_blocked_hashes.keys).to contain_exactly(
          [:last_name],
          [:last_name, :first_name],
          [:last_name, :birthday],
          [:last_name, :first_name, :birthday]
        )
        expect(detector.all_blocked_hashes[[:last_name, :first_name, :birthday]])
          .to eq Digest::MD5.hexdigest(".mustermann.max.1980-01-15 00:00:00")
      end
    end

    it "is empty if all attributes are blank" do
      expect(described_class.new(Person.new).all_blocked_hashes).to eq({})
    end
  end

  describe "#blocklisted?" do
    it "is false without matching entry" do
      expect(detector).not_to be_blocklisted
    end

    it "is true with matching entry" do
      BlocklistEntry.create!(blocked_hash: full_hash, hashed_attrs: %w[first_name last_name birthday])

      expect(detector).to be_blocklisted
    end

    it "is true without optional attribute if entry was created with it" do
      BlocklistEntry.create!(manual_person_attributes: {first_name: "Max", last_name: "Mustermann",
                                                        birthday: "1980-01-15"})
      person.birthday = nil

      expect(detector).to be_blocklisted
    end

    it "is false with optional attribute if entry was created without it" do
      BlocklistEntry.create!(manual_person_attributes: {first_name: "Max", last_name: "Mustermann"})

      expect(detector).not_to be_blocklisted
    end

    it "is false if all attributes are blank" do
      expect(described_class.new(Person.new)).not_to be_blocklisted
    end

    context "with multiple optional attributes" do
      with_hash_attrs([:last_name], [:first_name, :company_name])

      it "is false if the same value is given in another optional attribute" do
        BlocklistEntry.create!(manual_person_attributes: {last_name: "Smith", first_name: "Johnson"})
        person = Person.new(last_name: "Smith", company_name: "Johnson")

        expect(described_class.new(person)).not_to be_blocklisted
      end

      it "is true if the same value is given in the same optional attribute" do
        BlocklistEntry.create!(manual_person_attributes: {last_name: "Smith", first_name: "Johnson"})
        person = Person.new(last_name: "Smith", first_name: "Johnson")

        expect(described_class.new(person)).to be_blocklisted
      end
    end
  end

  describe "#blocklist_entry" do
    it "returns the matching entry" do
      entry = BlocklistEntry.create!(manual_person_attributes: {first_name: "Max", last_name: "Mustermann",
                                                                birthday: "1980-01-15"})

      expect(detector.blocklist_entry).to eq entry
    end

    it "ignores entry with same hash but other attributes" do
      BlocklistEntry.create!(blocked_hash: full_hash, hashed_attrs: %w[first_name last_name])

      expect(detector.blocklist_entry).to be_nil
    end
  end
end
