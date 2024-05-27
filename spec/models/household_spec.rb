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
      expect(household.remove_people.count).to eq(1)
      expect(household.remove_people.first).to eq(third_person)
      expect(household.save).to eq(true)
      expect(household.remove_people).to be_empty

      expect(household.reload.members.size).to eq(2)
    end

    it 'cannot be saved if all people removed' do
      create_household

      household.people.each do |p|
        household.remove(p)
      end
      expect(household.remove_people.count).to eq(3)
      expect(household.save).to eq(false)

      expect(household.reload.members.size).to eq(3)
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

    it 'is not valid if only one or less people in household' do
      expect(household).not_to be_valid

      expect(household.errors.count).to eq(1)
      expect(household.errors.first.attribute).to eq(:base)
      expect(household.errors.first.message).to include('Ein Haushalt muss aus mindestens zwei Personen bestehen')
    end
  end

  describe '#destroy' do
    it 'destroys whole household' do
      create_household

      household.destroy

      expect(Person.where(household_key: household.household_key)).not_to exist
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

    it 'removes person from household' do
      create_household
      expect(household.members.size).to eq(3)

      # third_person not included in params, so it should be removed
      household_attrs = [{ person_id: person.id },
                         { person_id: other_person.id }]

      household.household_members_attributes = household_attrs

      expect(household.remove_people.count).to eq(1)
      expect(household.remove_people).to include(third_person)
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
