# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe Household do
  subject(:household) { Household.new(person.reload) }

  let(:person) { Fabricate(:person, first_name: "David", last_name: "Hasselhoff") }
  let(:other_person) { Fabricate(:person, first_name: "Ardona", last_name: "Mola") }
  let(:third_person) { Fabricate(:person, first_name: "Malou", last_name: "Thomas") }

  describe "#people" do
    it "lists household members" do
      create_household

      expect(household.members.size).to eq(3)
      expect(household.people).to include(person)
      expect(household.people).to include(other_person)
      expect(household.people).to include(third_person)
    end
  end

  describe "#save" do
    it "creates new household and assigns same address to all members" do
      person.update!(street: "Greatstreet", housenumber: "345", zip_code: "3456", town: "Greattown", country: "CH")
      household.add(other_person)
      household.add(third_person)
      expect(household.new_people).to include(other_person)
      expect(household.new_people).to include(third_person)
      expect(household.save).to eq(true)
      expect(household.new_people).to be_empty

      household.reload

      expect(household.members.size).to eq(3)
      expect(household.people).to include(person)
      expect(household.people).to include(other_person)
      expect(household.people).to include(third_person)

      [person, other_person, third_person].each do |p|
        p.reload
        expect(p.address).to eq("Greatstreet 345")
        expect(p.zip_code).to eq("3456")
        expect(p.town).to eq("Greattown")
        expect(p.country).to eq("CH")
      end
    end

    it "adds person to existing household and assigns address" do
      create_household

      expect(household.members.size).to eq(3)
      fourth_person = Fabricate(:person)
      household.add(fourth_person)
      expect(household.members.size).to eq(4)
      expect(household.save).to eq(true)

      household.reload

      expect(household.members.size).to eq(4)
      expect(household.people).to include(person)
      expect(household.people).to include(other_person)
      expect(household.people).to include(third_person)
      expect(household.people).to include(fourth_person)
    end

    it "does not change anything if same person is added twice" do
      create_household

      household.add(person)
      expect(household.members.size).to eq(3)
      expect(household.save).to eq(true)

      household.reload

      expect(household.members.size).to eq(3)
    end

    it "can not be saved if not valid" do
      create_household
      fourth_person = Fabricate(:person)
      household.add(fourth_person)

      expect(household).to receive(:valid?).and_return(false)

      expect(household.save).to eq(false)
      expect(fourth_person.reload.household_key).to be_nil
    end

    it "removes person from existing household" do
      create_household
      expect(household.members.size).to eq(3)

      household.remove(third_person)
      expect(household.removed_people.count).to eq(1)
      expect(household.removed_people.first).to eq(third_person)
      expect(household.save).to eq(true)
      expect(household.removed_people).to be_empty

      expect(household.reload.members.size).to eq(2)
    end

    it "can be saved if all people removed" do
      create_household

      household.people.each do |p|
        household.remove(p)
      end
      expect(household.removed_people.count).to eq(3)
      expect(household.save).to eq(true)

      expect(Person.where(household_key: household.household_key)).not_to exist
    end

    it "destroys household if it has less than 2 members" do
      create_household

      household.remove(household.people.third)
      household.remove(household.people.second)
      expect(household.members).to have(1).item

      expect(household.save).to eq(true)

      expect(Person.where(household_key: household.household_key)).not_to exist
    end

    it "yields new_people and removed_people" do
      create_household

      household.remove(other_person)
      household.remove(third_person)
      added_person = Fabricate(:person)
      household.add(added_person)

      expect do |b|
        household.save(&b)
      end.to yield_with_args(contain_exactly(added_person), contain_exactly(other_person, third_person))
    end
  end

  describe "validation" do
    it "is not valid with person from other household" do
      other_household = create_other_household
      other_household_person = other_household.people.first
      other_household_person.update!(first_name: "Hans", last_name: "Halt")
      household.add(other_household_person)

      expect(household).not_to be_valid

      expect(household.errors.count).to eq(1)
      expect(household.errors.first.attribute).to eq(:"members[1].base")
      expect(household.errors.first.message).to eq("Hans Halt ist bereits Mitglied eines anderen Haushalts.")
    end

    it "is valid if only one or less people in household" do
      expect(household).to be_valid

      expect(household.errors).to be_empty
    end

    it "is not valid if it contains invalid person" do
      expect(household).to be_valid
      too_long_email = (("a" * 248) + "@example.com")
      allow(other_person).to receive(:email).and_return(too_long_email)
      expect(other_person).not_to be_valid

      household.add(other_person)

      expect(household).not_to be_valid

      expect(household.errors.count).to eq(1)
      expect(household.errors.first.attribute).to eq(:"members[1].person")
      expect(household.errors.first.message).to eq("Ardona Mola: Haupt-E-Mail ist zu lang (mehr als 255 Zeichen)")
    end
  end

  describe "address" do
    it "returns household attrs as hash" do
      person.update!(street: "Loriweg", housenumber: "42", zip_code: "6600", town: "Locarno", country: "CH")
      household.add(other_person)

      expected_attrs = {address_care_of: nil,
                        street: "Loriweg",
                        housenumber: "42",
                        postbox: nil,
                        country: "CH",
                        town: "Locarno",
                        zip_code: "6600"}

      expect(household.address_attrs).to eq(expected_attrs)
    end

    it "applies address from person with address when added to household without address" do
      create_household

      fourth_person = Fabricate(:person, street: "Loriweg", housenumber: "42")
      household.add(fourth_person)
      household.save
      expect(household.reload).to be_valid

      expected_attrs = {address_care_of: nil,
                        street: "Loriweg",
                        housenumber: "42",
                        postbox: nil,
                        country: nil,
                        town: nil,
                        zip_code: nil}

      expect(household.address_attrs).to eq(expected_attrs)
    end
  end

  describe "warnings" do
    it "has warning if only one or less people in household" do
      expect(household).to be_valid

      expect(household.errors).to be_empty
      expect(household.warnings.count).to eq(1)
      expect(household.warnings.first.attribute).to eq(:members)
      expect(household.warnings.first.message).to include("Der Haushalt wird aufgelöst da weniger als 2 Personen vorhanden sind.")
    end

    it "has warnings if members have different address data" do
      person.update!(street: "Loriweg", housenumber: "42", zip_code: "6600", town: "Locarno")
      household.add(other_person)

      expect(household).to be_valid

      expect(household.errors).to be_empty
      expect(household.warnings.count).to eq(1)
      expect(household.warnings.first.attribute).to eq(:members)
      expect(household.warnings.first.message).to include("Die Adresse 'Loriweg 42, 6600 Locarno' wird für alle Personen in diesem Haushalt übernommen.")
    end

    it "has warnings if reference person does not have an address but other member" do
      other_person.update!(street: "Other Loriweg", housenumber: "42", zip_code: "6600",
        town: "Locarno", country: "it")
      household.add(other_person)

      expect(household).to be_valid

      expect(household.errors).to be_empty
      expect(household.warnings.count).to eq(1)
      expect(household.warnings.first.attribute).to eq(:members)
      expect(household.warnings.first.message).to include("Die Adresse 'Other Loriweg 42, 6600 Locarno' wird für alle Personen in diesem Haushalt übernommen.")
    end

    it "has no warning of none of the members has address" do
      person.update!(street: "", housenumber: nil, zip_code: nil, town: "   ")
      household.add(other_person)

      expect(household).to be_valid

      expect(household.errors).to be_empty
      expect(household.warnings).to be_empty
    end
  end

  describe "#destroy" do
    it "destroys whole household" do
      create_household

      household.destroy

      expect(Person.where(household_key: household.household_key)).not_to exist
    end

    it "yields removed_people" do
      create_household
      original_people = household.people.dup

      expect do |b|
        household.destroy(&b)
      end.to yield_with_args(match_array(original_people))
    end
  end

  describe "logging" do
    with_versioning do
      let(:top_leader) { people(:top_leader) }
      before { PaperTrail.request.whodunnit = top_leader.id }
      after { PaperTrail.request.whodunnit = nil }

      it "adds log entry for every household member when creating new household" do
        household.add(other_person)

        expect do
          household.save
        end.to change { PaperTrail::Version.count }.by(2)

        [person, other_person].each do |person|
          log_entry = person.versions.last

          expect(log_line(log_entry)).to eq("Haushalt (David Hasselhoff, Ardona Mola) wurde neu erstellt.")

          expect(log_entry.whodunnit).to eq(top_leader.id.to_s)
          expect(log_entry.whodunnit_type).to eq(Person.sti_name)
        end
      end

      it "adds log entries for added people" do
        create_household

        fourth_person = Fabricate(:person, first_name: "Hans", last_name: "Hansen")
        household.add(fourth_person)
        fifth_person = Fabricate(:person, first_name: "Jan", last_name: "Miller")
        household.add(fifth_person)

        PaperTrail::Version.destroy_all

        expect do
          household.save
        end.to change { PaperTrail::Version.count }.by(10)

        [person, other_person, third_person, fourth_person, fifth_person].each do |person|
          version_entries = person.versions.last(2)

          expect(log_line(version_entries.first)).to eq("Hans Hansen wurde zum Haushalt (David Hasselhoff, Ardona Mola, Malou Thomas) hinzugefügt.")
          expect(log_line(version_entries.second)).to eq("Jan Miller wurde zum Haushalt (David Hasselhoff, Ardona Mola, Malou Thomas) hinzugefügt.")

          version_entries.each do |log_entry|
            expect(log_entry.whodunnit).to eq(top_leader.id.to_s)
            expect(log_entry.whodunnit_type).to eq(Person.sti_name)
          end
        end
      end

      it "adds log entries for from household removed person" do
        create_household

        expect do
          household.remove(other_person)
          household.save
        end.to change { PaperTrail::Version.count }.by(3)

        [person, other_person, third_person].each do |person|
          log_entry = person.versions.last

          expect(log_line(log_entry)).to eq("Ardona Mola wurde vom Haushalt (David Hasselhoff, Malou Thomas) entfernt.")

          expect(log_entry.whodunnit).to eq(top_leader.id.to_s)
          expect(log_entry.whodunnit_type).to eq(Person.sti_name)
        end
      end

      it "adds log entries for both, removed and added people" do
        create_household
        household.remove(third_person)
        household.save
        fourth_person = Fabricate(:person, first_name: "Hans", last_name: "Hansen")
        PaperTrail::Version.destroy_all

        household.remove(other_person)
        household.add(fourth_person)

        expect do
          household.save
        end.to change { PaperTrail::Version.count }.by(6)

        expect(collect_log_lines(person)).to eq([
          "Hans Hansen wurde zum Haushalt (David Hasselhoff) hinzugefügt.",
          "Ardona Mola wurde vom Haushalt (David Hasselhoff) entfernt."
        ])

        expect(collect_log_lines(other_person)).to eq([
          "Hans Hansen wurde zum Haushalt (David Hasselhoff) hinzugefügt.",
          "Ardona Mola wurde vom Haushalt (David Hasselhoff) entfernt."
        ])

        expect(collect_log_lines(fourth_person)).to eq([
          "Hans Hansen wurde zum Haushalt (David Hasselhoff) hinzugefügt.",
          "Ardona Mola wurde vom Haushalt (David Hasselhoff) entfernt."
        ])

        expect_whodunnit_top_leader
      end

      it "raises exception if whodunnit not set" do
        allow(PaperTrail.request).to receive(:whodunnit)

        expect do
          create_household
        end.to raise_error(RuntimeError, "PaperTrail.request.whodunnit must be set")
      end

      it "add log entry to all former members for destroyed household" do
        create_household

        expect do
          household.destroy
        end.to change { PaperTrail::Version.count }.by(3)

        [person, other_person, third_person].each do |person|
          log_entry = person.versions.last

          expect(log_line(log_entry)).to eq("Haushalt (David Hasselhoff, Ardona Mola, Malou Thomas) wurde aufgelöst.")

          expect(log_entry.whodunnit).to eq(top_leader.id.to_s)
          expect(log_entry.whodunnit_type).to eq(Person.sti_name)
        end
      end

      it "adds address changed log entry to members when creating new household" do
        person.update!(street: "Loriweg", housenumber: "42", zip_code: "6600", town: "Locarno")
        other_person # create person and remove related version entry
        PaperTrail::Version.destroy_all

        household.add(other_person)

        expect do
          household.save
        end.to change { PaperTrail::Version.count }.by(3)

        expect(person.versions.count).to eq(1)

        # one version entry for created household, the other for changed address
        expect(other_person.versions.count).to eq(2)
        address_log_entry = other_person.versions.first
        expect(log_line(address_log_entry)).to eq("PLZ wurde auf <i>6600</i> gesetzt.</div><div>Ort wurde auf <i>Locarno</i> gesetzt.</div><div>Strasse wurde auf <i>Loriweg</i> gesetzt.</div><div>Hausnummer wurde auf <i>42</i> gesetzt.")

        expect_whodunnit_top_leader
      end
    end
  end

  private

  def create_household
    household = Household.new(person)
    household.add(other_person)
    household.add(third_person)
    household.save
    household.reload
  end

  def create_other_household
    household = Household.new(Fabricate(:person))
    household.add(Fabricate(:person))
    household.add(Fabricate(:person))
    household.save
    household.reload
  end

  def collect_log_lines(person)
    person.versions.collect do |version|
      log_line(version)
    end
  end

  def log_line(version)
    version
      .decorate
      .changes
      .gsub(/\A<div>(.*?)<\/div>\z/, '\1')
  end

  def expect_whodunnit_top_leader
    all_by_top_leader = PaperTrail::Version.all.all? do |version|
      version.whodunnit == top_leader.id.to_s &&
        version.whodunnit_type == Person.sti_name
    end
    expect(all_by_top_leader).to eq(true)
  end
end
