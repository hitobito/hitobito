# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe ChangelogVersion do
  describe "#initialize" do
    it "parses the version string correctly" do
      version = ChangelogVersion.new("1.2")
      expect(version.major_version).to eq(1)
      expect(version.minor_version).to eq(2)
      expect(version.version).to eq("1.2")
    end

    it "handles missing minor version correctly" do
      version = ChangelogVersion.new("1")
      expect(version.major_version).to eq(1)
      expect(version.minor_version).to eq(0)
      expect(version.version).to eq("1")
    end

    it "handles wildcard versions" do
      version = ChangelogVersion.new("1.*")
      expect(version.major_version).to eq(1)
      expect(version.minor_version).to eq(Float::INFINITY)
      expect(version.version).to eq("1.*")

      version = ChangelogVersion.new("2.x")
      expect(version.major_version).to eq(2)
      expect(version.minor_version).to eq(Float::INFINITY)
      expect(version.version).to eq("2.x")
    end

    it "handles unreleased versions" do
      version = ChangelogVersion.new("unreleased")
      expect(version.major_version).to eq(Float::INFINITY)
      expect(version.minor_version).to eq(Float::INFINITY)
      expect(version.version).to eq("unreleased")
    end

    it "handles empty version strings" do
      version = ChangelogVersion.new("")
      expect(version.major_version).to eq(0)
      expect(version.minor_version).to eq(0)
      expect(version.version).to eq("")
    end

    it "handles nil version strings" do
      version = ChangelogVersion.new(nil)
      expect(version.major_version).to eq(0)
      expect(version.minor_version).to eq(0)
      expect(version.version).to eq("")
    end
  end

  describe "#<=>" do
    it "compares versions correctly" do
      version1 = ChangelogVersion.new("1.2")
      version2 = ChangelogVersion.new("1.3")
      version3 = ChangelogVersion.new("2.0")
      version4 = ChangelogVersion.new("1.*")
      version5 = ChangelogVersion.new("unreleased")

      expect(version1 <=> version2).to eq(-1)
      expect(version2 <=> version3).to eq(-1)
      expect(version3 <=> version1).to eq(1)
      expect(version1 <=> version4).to eq(-1)
      expect(version4 <=> version5).to eq(-1)
      expect(version5 <=> version5).to eq(0)
    end
  end
end
