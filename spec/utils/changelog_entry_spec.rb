# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe ChangelogEntry do
  describe "ChangelogEntry::CORE_ISSUE_HASH_REGEX" do
    [
      "matching 1 hitobito#123",
      "matching 2 #123",
      "matching 3 (hitobito#123)",
      "matching 4 (#123, merci @Donald!)",
      "matching 5 'hitobito#123' well done",
      "matching 6 '#123' thanks 😀"
    ].each do |string|
      it "matches '#{string}'" do
        expect(string)
          .to match(ChangelogEntry::CORE_ISSUE_HASH_REGEX)
          .with_captures(number: "123")
      end
    end

    [
      "not matching 1 hitobito#123abc",
      "not matching 2 hitobito_sac_cas/hitobito#123",
      "not matching 3 hellohitobito#123"
    ].each do |string|
      it "does not match '#{string}'" do
        expect(string).not_to match(ChangelogEntry::CORE_ISSUE_HASH_REGEX)
      end
    end
  end

  describe "ChangelogEntry::WAGON_ISSUE_HASH_REGEX" do
    [
      "matching hitobito_sac_cas#123",
      "matching hitobito/hitobito_sac_cas#123, thanks!",
      "matching (hitobito_sac_cas#123 and others)"
    ].each do |string|
      it "matches '#{string}'" do
        expect(string)
          .to match(ChangelogEntry::WAGON_ISSUE_HASH_REGEX)
          .with_captures(wagon: "hitobito_sac_cas", number: "123")
      end
    end

    [
      "not matching 1 hitobito#123",
      "not matching 2 #123",
      "not matching 3 (hitobito#123)",
      "not matching 4 (#123, merci @Donald!)",
      "not matching 5 'hitobito#123' well done",
      "not matching 6 '#123' thanks 😀",
      "not matching 7 hellohitobito/hitobito_sac_cas#123",
      "not matching 8 hitobito_sac_cas#123abc"
    ].each do |string|
      it "does not match '#{string}'" do
        expect(string).not_to match(ChangelogEntry::WAGON_ISSUE_HASH_REGEX)
      end
    end
  end
end
