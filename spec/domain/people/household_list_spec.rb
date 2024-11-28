# frozen_string_literal: true

#  Copyright (c) 2021, Die Mitte Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe People::HouseholdList do
  subject(:household_list) { described_class.new(scope) }

  let(:person1) { Fabricate(:person) }
  let(:person2) { Fabricate(:person) }
  let(:person3) { Fabricate(:person, household_key: "1234") }
  let(:person4) { Fabricate(:person, household_key: "1234") }
  let(:person5) { Fabricate(:person, household_key: 1111) }
  let(:scope) { Person.where(id: [person1, person2, person3, person4, person5]) }

  describe "#people_without_household_in_batches" do
    subject(:list) { household_list.people_without_household_in_batches.map(&:itself) }

    it "returns only people with nil household_key" do
      expect(list).to contain_exactly([person1], [person2])
    end

    context "with limited people scope" do
      let(:scope) { Person.where(id: [person1, person2, person3, person4, person5]).limit(1) }

      it "respects limit" do
        expect(list).to contain_exactly([scope.first])
      end
    end
  end

  describe "#only_households_in_batches" do
    subject(:list) { household_list.only_households_in_batches.map(&:itself) }

    it "returns only people with nil household_key" do
      expect(list).to contain_exactly(contain_exactly(person3, person4), [person5])
    end
  end

  describe "#households_in_batches" do
    let(:scope) { Person.where(id: [person1, person2, person3, person4, person5]) }

    subject(:list) { household_list.households_in_batches.map(&:itself) }

    it "returns grouped households" do
      expect(list).to contain_exactly(
        [person1],
        [person2],
        [person3, person4],
        [person5]
      )
    end

    context "with limited people scope" do
      let(:scope) { Person.where(id: [person1, person2, person3, person4, person5]).limit(2) }

      it "respects limit" do
        expect(list.size).to eq(2)
      end
    end

    context "with given order" do
      let(:scope) { Person.where(id: [person1, person2, person3, person4, person5]).order(order) }

      context "with last_name DESC" do
        let(:order) { {last_name: :DESC} }

        it "keeps order" do
          last_names = list.map { |household| household.first.last_name }
          expect(last_names).to eq(last_names.sort.reverse)
        end
      end

      context "with first_name ASC" do
        let(:order) { {first_name: :ASC} }

        it "keeps order" do
          first_names = list.map { |household| household.first.first_name }
          expect(first_names).to eq(first_names.sort)
        end
      end
    end

    context "limited people scope" do
      let(:scope) do
        Person.where(id: [person1, person2, person3, person4, person5, person6, person7]).limit(3)
      end
      let(:person6) { Fabricate(:person, household_key: "1234") }
      let(:person7) { Fabricate(:person, household_key: "1234") }
      let!(:person_not_in_scope) { Fabricate(:person, household_key: "1234") }

      it "respects limit, but still groups all housemates from scope" do
        expect(list).to contain_exactly(
          [person1],
          [person2],
          contain_exactly(person3, person4, person6, person7)
        )
      end
    end

    context "people scope with selects" do
      let(:scope) do
        Person.where(id: [person1, person2, person3, person4, person5, person6,
          person7]).only_public_data
      end
      let(:person6) { Fabricate(:person, household_key: "1234") }
      let(:person7) { Fabricate(:person, household_key: "1234") }
      let!(:person_not_in_scope) { Fabricate(:person, household_key: 1111) }

      it "works" do
        expect(list).to contain_exactly(
          contain_exactly(person3, person4, person6, person7),
          [person1],
          [person2],
          [person5]
        )
      end
    end
  end

  describe "enumerable" do
    let(:scope) { Person.all }

    it "is enumerable" do
      expect(subject).to be_an Enumerable
      expect(household_list.each).to be_an Enumerator
    end
  end
end
