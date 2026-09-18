# frozen_string_literal: true

#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "rails_helper"
require_relative "../../db/migrate/20260908151830_add_canton_to_people"

RSpec.describe AddCantonToPeople, type: :migration do
  subject(:migration) { described_class.new }

  around do |example|
    ActiveRecord::Migration.verbose = false
    example.run
    ActiveRecord::Migration.verbose = true
  end

  def create_person(canton:, country: "CH")
    Fabricate(:person).tap do |person|
      person.update_columns(country:, canton:)
    end
  end

  describe "#normalize_canton_values" do
    it "trims and downcases existing values" do
      person = create_person(canton: " ZH ")
      migration.send(:normalize_canton_values)
      expect(person.reload.canton).to eq "zh"
    end

    it "turns a blank string into NULL" do
      person = create_person(canton: "   ")
      migration.send(:normalize_canton_values)
      expect(person.reload.canton).to be_nil
    end
  end

  describe "#recover_full_text_canton_values" do
    it "translates a full canton name to its short code" do
      person = create_person(canton: "Zürich")
      migration.send(:normalize_canton_values)
      migration.send(:recover_full_text_canton_values)
      expect(person.reload.canton).to eq "zh"
    end

    it "normalizes punctuation and whitespace variants alike" do
      dotted = create_person(canton: "St.Gallen")
      spaced = create_person(canton: "St. Gallen")
      migration.send(:normalize_canton_values)
      migration.send(:recover_full_text_canton_values)
      expect(dotted.reload.canton).to eq "sg"
      expect(spaced.reload.canton).to eq "sg"
    end

    it "normalizes hyphenated names" do
      person = create_person(canton: "Basel-Land")
      migration.send(:normalize_canton_values)
      migration.send(:recover_full_text_canton_values)
      expect(person.reload.canton).to eq "bl"
    end

    it "matches against french and italian translations too" do
      french = create_person(canton: "Genève")
      italian = create_person(canton: "Ginevra")
      migration.send(:normalize_canton_values)
      migration.send(:recover_full_text_canton_values)
      expect(french.reload.canton).to eq "ge"
      expect(italian.reload.canton).to eq "ge"
    end

    it "leaves genuine garbage untouched" do
      person = create_person(canton: "not a canton")
      migration.send(:normalize_canton_values)
      migration.send(:recover_full_text_canton_values)
      expect(person.reload.canton).to eq "not a canton"
    end

    it "does not touch an already-valid short code" do
      person = create_person(canton: "zh")
      migration.send(:normalize_canton_values)
      migration.send(:recover_full_text_canton_values)
      expect(person.reload.canton).to eq "zh"
    end
  end

  describe "#clear_invalid_canton_values" do
    it "clears a value that matches no canton" do
      person = create_person(canton: "not a canton")
      migration.send(:clear_invalid_canton_values)
      expect(person.reload.canton).to be_nil
    end

    it "keeps a valid short code" do
      person = create_person(canton: "zh")
      migration.send(:clear_invalid_canton_values)
      expect(person.reload.canton).to eq "zh"
    end
  end

  describe "#clear_canton_for_non_swiss_people" do
    it "clears canton when the country is explicitly non-Swiss" do
      person = create_person(canton: "zh", country: "DE")
      migration.send(:clear_canton_for_non_swiss_people)
      expect(person.reload.canton).to be_nil
    end

    it "keeps canton when the country is Swiss" do
      person = create_person(canton: "zh", country: "CH")
      migration.send(:clear_canton_for_non_swiss_people)
      expect(person.reload.canton).to eq "zh"
    end

    it "keeps canton when the country is blank and the instance defaults to Switzerland" do
      person = create_person(canton: "zh", country: nil)
      migration.send(:clear_canton_for_non_swiss_people)
      expect(person.reload.canton).to eq "zh"
    end

    it "clears canton when the country is blank and the instance does not default to Switzerland" do
      allow(Countries).to receive(:default).and_return("de")
      person = create_person(canton: "zh", country: nil)
      migration.send(:clear_canton_for_non_swiss_people)
      expect(person.reload.canton).to be_nil
    end
  end

  it "runs the full cleanup pipeline in the correct order" do
    recoverable = create_person(canton: "St.Gallen", country: "CH")
    bad_combo = create_person(canton: "zh", country: "DE")
    garbage = create_person(canton: "#NV", country: "CH")

    migration.send(:normalize_canton_values)
    migration.send(:recover_full_text_canton_values)
    migration.send(:clear_invalid_canton_values)
    migration.send(:clear_canton_for_non_swiss_people)

    expect(recoverable.reload.canton).to eq "sg"
    expect(bad_combo.reload.canton).to be_nil
    expect(garbage.reload.canton).to be_nil
  end
end
