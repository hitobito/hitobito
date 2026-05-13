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
