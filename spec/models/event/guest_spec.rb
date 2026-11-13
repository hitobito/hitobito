# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Event::Guest do
  let(:guest) { Event::Guest.new }

  describe "#gender" do
    it "is valid with a known gender" do
      guest.gender = "m"
      expect(guest.gender).to eq "m"
      guest.gender = "w"
      expect(guest.gender).to eq "w"
    end

    it "is valid with nil" do
      guest.gender = nil
      expect(guest).to be_valid
    end

    it "is invalid with a gender that is not defined" do
      guest.gender = "something"
      expect(guest).not_to be_valid
    end
  end

  describe "#to_person" do
    it "copies address_care_of and address_addition" do
      guest.assign_attributes(address_care_of: "c/o Muster", address_addition: "Hinterhaus")
      expect(guest.to_person).to have_attributes(address_care_of: "c/o Muster",
        address_addition: "Hinterhaus")
    end
  end

  describe "#language" do
    it "is valid with a defined language" do
      guest.language = "de"
      expect(guest).to be_valid
    end

    it "is valid with nil" do
      guest.language = nil
      expect(guest).to be_valid
    end

    it "is invalid with a language outside defined languages" do
      guest.language = "rm"
      expect(guest).not_to be_valid
    end
  end

  describe "#to_person" do
    let(:guest) { Event::Guest.new(first_name: "Gaby", phone_number: "+41 79 123 45 67") }

    it "builds the phone number as mobile number" do
      phone_number = guest.to_person.phone_numbers.first

      expect(phone_number.number).to eq "+41 79 123 45 67"
      expect(phone_number.category).to eq contact_account_categories(:phone_number_person_mobile)
    end

    it "builds no phone number if guest has none" do
      guest.phone_number = nil

      expect(guest.to_person.phone_numbers).to be_empty
    end

    it "does not query the phone number category for every guest" do
      guest.to_person
      other_guests = Array.new(3) { Event::Guest.new(phone_number: "+41 79 000 00 00") }

      expect { other_guests.each(&:to_person) }.not_to make.db_queries
    end
  end

  context "#years" do
    before { travel_to Time.zone.local(2021, 5, 24) }

    it "is nil if guest has no birthday" do
      expect(Event::Guest.new.years).to be_nil
    end

    [[Date.new(2006, 2, 12), 15],
      [Date.new(2005, 3, 15), 16],
      [Date.new(2004, 2, 29), 17]].each do |birthday, years|
      it "is #{years} years old if born on #{birthday}" do
        expect(Event::Guest.new(birthday: birthday).years).to eq years
      end
    end
  end
end
