# frozen_string_literal: true

#  Copyright (c) 2021, Die Mitte Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe People::HouseholdList do

  let(:subject) { described_class.new(scope) }
  let(:person1) { Fabricate(:person) }
  let(:person2) { Fabricate(:person) }
  let(:person3) { Fabricate(:person, household_key: '1234-1234-1234-1234') }
  let(:person4) { Fabricate(:person, household_key: '1234-1234-1234-1234') }
  let(:person5) { Fabricate(:person, household_key: 'abcd-abcd-abcd-abcd') }

  context '#people_without_households' do
    let(:scope) { Person.where(id: [person1, person2, person3, person4, person5]) }

    it 'returns only people with nil household_key' do
      expect(subject.people_without_household).to eq([person1, person2])
    end

    context 'limited people scope' do
      let(:scope) { Person.where(id: [person1, person2, person3, person4, person5]).limit(1) }

      it 'respects limit' do
        expect(subject.people_without_household).to eq([person1])
      end
    end

  end

  context '#grouped_households' do
    let(:scope) { Person.where(id: [person1, person2, person3, person4, person5]) }

    it 'returns grouped households' do
      expect(subject.grouped_households.map(&:key)).to match_array([
          person1.id.to_s,
          person2.id.to_s,
          person3.household_key,
          person5.household_key,
      ])
    end

    context 'limited people scope' do
      let(:scope) { Person.where(id: [person1, person2, person3, person4, person5]).limit(2) }

      it 'respects limit' do
        expect(subject.grouped_households.to_a.count).to eq(2)
      end
    end
  end

  context '#households_in_batches' do
    let(:scope) { Person.where(id: [person1, person2, person3, person4, person5]) }

    it 'yields a list of household arrays, orders by descending household size' do
      yielded_batch = []
      subject.households_in_batches { |batch| yielded_batch = batch }
      expect(yielded_batch.map{ |household| household.map(&:id) }).to eq([
          [person3.id, person4.id],
          [person5.id],
          [person1.id],
          [person2.id]
      ])
    end

    it 'yields only rows with household_key when told to exclude_non_households' do
      yielded_batch = []
      subject.households_in_batches(exclude_non_households: true) { |batch| yielded_batch = batch }
      expect(yielded_batch.map{ |household| household.map(&:id) }).to eq([
          [person3.id, person4.id],
          [person5.id]
      ])
    end

    context 'limited people scope' do
      let(:scope) { Person.where(id: [person1, person2, person3, person4, person5, person6, person7]).limit(2) }
      let(:person6) { Fabricate(:person, household_key: '1234-1234-1234-1234') }
      let(:person7) { Fabricate(:person, household_key: '1234-1234-1234-1234') }
      let!(:person_not_in_scope) { Fabricate(:person, household_key: '1234-1234-1234-1234') }

      it 'respects limit, but still groups all housemates from scope' do
        yielded_batch = []
        subject.households_in_batches { |batch| yielded_batch = batch }
        expect(yielded_batch.map{ |household| household.map(&:id) }).to eq([
            [person3.id, person4.id, person6.id, person7.id],
            [person5.id]
        ])
      end
    end

    context 'people scope with selects' do
      let(:scope) { Person.where(id: [person1, person2, person3, person4, person5, person6, person7]).only_public_data }
      let(:person6) { Fabricate(:person, household_key: '1234-1234-1234-1234') }
      let(:person7) { Fabricate(:person, household_key: '1234-1234-1234-1234') }
      let!(:person_not_in_scope) { Fabricate(:person, household_key: '1234-1234-1234-1234') }

      it 'works' do
        yielded_batch = []
        subject.households_in_batches { |batch| yielded_batch = batch }
        expect(yielded_batch.map{ |household| household.map(&:id) }).to eq([
            [person3.id, person4.id, person6.id, person7.id],
            [person5.id],
            [person1.id],
            [person2.id]
        ])
      end
    end
  end

  context 'enumerable' do
    let(:scope) { Person.all }

    it 'is enumerable' do
      expect(subject).to be_an Enumerable
      expect(subject.each).to be_an Enumerator
    end
  end
end
