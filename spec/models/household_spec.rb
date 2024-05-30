# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require 'spec_helper'

describe Household do

  subject(:household) { Household.new(person.reload) }
  let(:person) { people(:bottom_member) }
  let(:other_person) { Fabricate(:person) }
  let(:third_person) { Fabricate(:person) }

  describe '#people' do

    it 'lists household members' do
      create_household

      expect(household.members.size).to eq(3)
      expect(household.people).to include(person)
      expect(household.people).to include(other_person)
      expect(household.people).to include(third_person)
    end
  end

  describe '#save' do
    it 'creates new household and assigns same address to all members' do
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
        expect(p.address).to eq('Greatstreet 345')
        expect(p.zip_code).to eq('3456')
        expect(p.town).to eq('Greattown')
        expect(p.country).to eq('CH')
      end
    end

    it 'adds person to existing household and assigns address' do
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

    it 'does not change anything if same person is added twice' do
      create_household

      household.add(person)
      expect(household.members.size).to eq(3)
      expect(household.save).to eq(true)

      household.reload

      expect(household.members.size).to eq(3)
    end

    it 'can not be saved if not valid' do
      create_household
      fourth_person = Fabricate(:person)
      household.add(fourth_person)

      expect(household).to receive(:valid?).and_return(false)

      expect(household.save).to eq(false)
      expect(fourth_person.reload.household_key).to be_nil
    end

    it 'removes person from existing household' do
      create_household
      expect(household.members.size).to eq(3)

      household.remove(third_person)
      expect(household.removed_people.count).to eq(1)
      expect(household.removed_people.first).to eq(third_person)
      expect(household.save).to eq(true)
      expect(household.removed_people).to be_empty

      expect(household.reload.members.size).to eq(2)
    end

    it 'can be saved if all people removed' do
      create_household

      household.people.each do |p|
        household.remove(p)
      end
      expect(household.removed_people.count).to eq(3)
      expect(household.save).to eq(true)

      expect(Person.where(household_key: household.household_key)).not_to exist
    end

    it 'destroys household if it has less than 2 members' do
      create_household

      household.remove(household.people.third)
      household.remove(household.people.second)
      expect(household.members).to have(1).item

      expect(household.save).to eq(true)

      expect(Person.where(household_key: household.household_key)).not_to exist
    end

    it 'yields new_people and removed_people' do
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

  describe 'validation' do
    it 'is not valid with person from other household' do
      other_household = create_other_household
      other_household_person = other_household.people.first
      other_household_person.update!(first_name: 'Hans', last_name: 'Halt')
      household.add(other_household_person)

      expect(household).not_to be_valid

      expect(household.errors.count).to eq(1)
      expect(household.errors.first.attribute).to eq(:'members[1].base')
      expect(household.errors.first.message).to eq('Hans Halt ist bereits Mitglied eines anderen Haushalts')
    end

    it 'is valid if only one or less people in household' do
      expect(household).to be_valid

      expect(household.errors).to be_empty
    end
  end

  describe 'address' do
    it 'returns household attrs as hash' do
      person.update!(address: 'Loriweg 42', zip_code: '6600', town: 'Locarno')
      household.add(other_person)

      expected_attrs = { 'address' => 'Loriweg 42',
                         'country' => 'CH',
                         'town' => 'Locarno',
                         'zip_code' => '6600'}

      expect(household.address_attrs).to eq(expected_attrs)
    end

    it 'applies address from person with address when added to household without address' do
      create_household

      fourth_person = Fabricate(:person, address: 'Loriweg 42')
      household.add(fourth_person)
      household.save
      expect(household).to be_valid

      expected_attrs = { 'address' => 'Loriweg 42',
                         'country' => nil,
                         'town' => nil,
                         'zip_code' => nil }

      expect(household.address_attrs).to eq(expected_attrs)
    end
  end

  describe 'warnings' do
    it 'has warning if only one or less people in household' do
      expect(household).to be_valid

      expect(household.errors).to be_empty
      expect(household.warnings.count).to eq(1)
      expect(household.warnings.first.attribute).to eq(:members)
      expect(household.warnings.first.message).to include('Der Haushalt wird aufelöst da weniger als 2 Personen vorhanden sind.')
    end

    it 'has warnings if members have different address data' do
      person.update!(address: 'Loriweg 42', zip_code: '6600', town: 'Locarno')
      household.add(other_person)

      expect(household).to be_valid

      expect(household.errors).to be_empty
      expect(household.warnings.count).to eq(1)
      expect(household.warnings.first.attribute).to eq(:members)
      expect(household.warnings.first.message).to include("Die Adresse 'Loriweg 42, 6600 Locarno' wird für alle Personen in diesem Haushalt übernommen.")
    end

    it 'has warnings if reference person does not have an address but other member' do
      other_person.update!(address: 'Other Loriweg 42', zip_code: '6600', town: 'Locarno', country: 'it')
      household.add(other_person)

      expect(household).to be_valid

      expect(household.errors).to be_empty
      expect(household.warnings.count).to eq(1)
      expect(household.warnings.first.attribute).to eq(:members)
      expect(household.warnings.first.message).to include("Die Adresse 'Other Loriweg 42, 6600 Locarno' wird für alle Personen in diesem Haushalt übernommen.")
    end

    it 'has no warning of none of the members has address' do
      person.update!(address: '', zip_code: nil, town: '   ')
      household.add(other_person)

      expect(household).to be_valid

      expect(household.errors).to be_empty
      expect(household.warnings).to be_empty
    end
  end

  describe '#destroy' do
    it 'destroys whole household' do
      create_household

      household.destroy

      expect(Person.where(household_key: household.household_key)).not_to exist
    end

    it 'yields removed_people' do
      create_household
      original_people = household.people.dup

      expect do |b|
        household.destroy(&b)
      end.to yield_with_args(match_array(original_people))
    end
  end

  describe '#household_members_attributes= / params' do
    it 'adds person to household' do
      create_household
      fourth_person = Fabricate(:person)

      household_attrs = [{ person_id: person.id },
                         { person_id: other_person.id },
                         { person_id: third_person.id },
                         { person_id: fourth_person.id }]

      household.household_members_attributes = household_attrs

      expect(household.save).to eq(true)

      expect(household.reload.members.size).to eq(4)
      expect(household.people).to include(person)
      expect(household.people).to include(other_person)
      expect(household.people).to include(third_person)
      expect(household.people).to include(fourth_person)
    end

    it 'creates new household' do
    end

    it 'removes person from household' do
      create_household
      expect(household.members.size).to eq(3)

      # third_person not included in params, so it should be removed
      household_attrs = [{ person_id: person.id },
                         { person_id: other_person.id }]

      household.household_members_attributes = household_attrs

      expect(household.removed_people.count).to eq(1)
      expect(household.removed_people).to include(third_person)
      expect(household.save).to eq(true)

      expect(household.reload.members.size).to eq(2)
      expect(household.people).to include(person)
      expect(household.people).to include(other_person)
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

end
