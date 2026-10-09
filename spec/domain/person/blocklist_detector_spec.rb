# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Person::BlocklistDetector do
  let(:person) { Person.new(first_name: "Max", last_name: "Mustermann", birthday: "1980-01-15") }

  subject(:detector) { described_class.new(person) }

  describe "#blocked_hash" do
    it "is compatible with the hashes of the legacy system" do
      expect(detector.blocked_hash).to eq Digest::MD5.hexdigest(".max.mustermann.1980-01-15 00:00:00")
    end

    it "ignores surrounding whitespace and case" do
      person.first_name = "  MAX "
      person.last_name = "MusterMann\t"

      expect(detector.blocked_hash).to eq Digest::MD5.hexdigest(".max.mustermann.1980-01-15 00:00:00")
    end

    it "skips blank attributes" do
      person.birthday = nil

      expect(detector.blocked_hash).to eq Digest::MD5.hexdigest(".max.mustermann")
    end

    it "is nil if all attributes are blank" do
      expect(described_class.new(Person.new).blocked_hash).to be_nil
    end
  end

  describe "#blocklisted?" do
    it "is false without matching entry" do
      expect(detector).not_to be_blocklisted
    end

    it "is true with matching entry" do
      BlocklistEntry.create!(blocked_hash: detector.blocked_hash)

      expect(detector).to be_blocklisted
    end

    it "is false if all attributes are blank" do
      expect(described_class.new(Person.new)).not_to be_blocklisted
    end
  end
end
