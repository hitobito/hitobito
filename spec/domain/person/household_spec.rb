#  Copyright (c) 2012-2018, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Person::Household do

  let(:leader) { people(:top_leader) }
  let(:member) { people(:bottom_member) }

  let(:user) { Person.first }

  def create(role, group)
    Fabricate(role.name.to_s, group: group).person
  end

  def household(person)
    Person::Household.new(person, Ability.new(person), nil, user)
  end

  context '#assign' do
    def assign_household(person, other)
      Person::Household.new(person, Ability.new(person), other).tap(&:assign)
    end

    it 'adding self resets address' do
      leader.town = 'dummy'
      household = assign_household(leader, Person.find(leader.id))

      expect(leader.town).to eq 'Supertown'
      expect(leader.household_people_ids).to be_empty
      expect(household).to be_address_changed
      expect(household).not_to be_people_changed
    end

    it 'copies address and adds person to people' do
      household = assign_household(leader, member)

      expect(leader.town).to eq 'Greattown'
      expect(leader.household_people_ids).to eq [member.id]
      expect(household).to be_address_changed
      expect(household).to be_people_changed
    end

    it 'adds all household people' do
      other = create(Group::BottomLayer::Leader, groups(:bottom_layer_one))
      other.update(household_key: 1)
      member.update(household_key: 1)

      household = assign_household(leader, member)

      expect(leader.town).to eq 'Greattown'
      expect(leader.household_people_ids).to match_array [other.id, member.id]
      expect(household).to be_address_changed
      expect(household).to be_people_changed
    end

    it 'adds first non writable person' do
      household = assign_household(member, leader)

      expect(member.town).to eq 'Supertown'
      expect(member.household_people_ids).to eq [leader.id]
      expect(household).to be_address_changed
      expect(household).to be_people_changed
    end

    it 'does not add another non writeable person' do
      leader.update(household_key: 1)
      member.update(household_key: 1)

      other = create(Group::TopGroup::Leader, groups(:top_group))
      household = assign_household(member, other)

      expect(member.household_people_ids).to eq [leader.id]
      expect(household).not_to be_address_changed
      expect(household).not_to be_people_changed
    end

    it 'does add another non writable person if address identical' do
      leader.update(household_key: 1)
      member.update(household_key: 1)

      other = create(Group::TopGroup::Leader, groups(:top_group))
      other.update(town: 'Supertown')
      household = assign_household(member, other)

      expect(member.household_people_ids).to eq [leader.id, other.id]
      expect(household).not_to be_address_changed
      expect(household).to be_people_changed
    end

    it 'does add another writable person if address is different' do
      other = create(Group::BottomLayer::Leader, groups(:bottom_layer_one))
      other.update(town: 'Supertown')
      leader.update(household_key: 1)
      other.update(household_key: 1)

      household = assign_household(other, member)

      expect(other.household_people_ids).to eq [leader.id, member.id]
      expect(household).not_to be_address_changed
      expect(household).to be_people_changed
    end
  end

  context "#valid?" do
    it 'true if person address is identical to readonly person address' do
      member.household_people_ids = [leader.id]
      member.attributes = leader.attributes.slice(*Person::ADDRESS_ATTRS)

      expect(household(member)).to be_valid
    end

    it 'false if person address is not identical to readonly person address' do
      member.household_people_ids = [leader.id]
      expect(household(member)).not_to be_valid
      expect(member.errors).to have_key(:town)
      expect(member.errors.full_messages).to eq [
        "Adresse : Du hast nicht auf alle Personen aus dem Haushalt Schreibrechte. Entferne Top Leader aus dem Haushalt, um die Adresse anzupassen.",
         "PLZ : Du hast nicht auf alle Personen aus dem Haushalt Schreibrechte. Entferne Top Leader aus dem Haushalt, um die Adresse anzupassen.",
         "Ort : Du hast nicht auf alle Personen aus dem Haushalt Schreibrechte. Entferne Top Leader aus dem Haushalt, um die Adresse anzupassen.",
         "Land : Du hast nicht auf alle Personen aus dem Haushalt Schreibrechte. Entferne Top Leader aus dem Haushalt, um die Adresse anzupassen."
      ]
    end
  end

  context '#save' do
    it 'persists new household', versioning: true do
      leader.household_people_ids = [member.id]
      expect do
        household(leader).save
      end.to change { member.versions.count }.by(2)

      expect(leader.reload.household_key).to eq member.reload.household_key
      expect(leader.household_key).to be_present
      expect(member.household_key).to be_present
      expect(leader.household_people).to eq [member]
    end

    it 'persists new household with readonly person' do
      member.attributes = leader.attributes.slice(*Person::ADDRESS_ATTRS)
      member.household_people_ids = [leader.id]
      household(member).save

      expect(member.reload.household_key).to eq leader.reload.household_key
      expect(member.household_key).to be_present
      expect(leader.household_key).to be_present
      expect(member.household_people).to eq [leader]
    end

    it 'adds person to persisted household' do
      member.update(household_key: 1)
      leader.household_people_ids = [member.id]
      household(leader).save

      expect(leader.reload.household_key).to eq '1'
      expect(leader.household_people).to eq [member]
    end

    it 'combines two existing households' do
      other = create(Group::BottomLayer::Leader, groups(:bottom_layer_one))
      member.update(household_key: 1)
      leader.update(household_key: 2)

      other.attributes = leader.attributes.slice(*Person::ADDRESS_ATTRS)
      other.household_people_ids = [leader.id, member.id]
      household(other).save

      expect(other.reload.household_key).to eq '1'
      expect(other.household_people).to match_array [leader, member]
      expect(other.town).to eq 'Supertown'
      expect(member.reload.town).to eq 'Supertown'
    end

    it 'raises if person address attrs differ from readonly person address attrs' do
      member.household_people_ids = [leader.id]
      expect do
        household(member).save
      end.to raise_error 'invalid'
    end

    it 'raises if two readonly people have different addresses' do
      other = create(Group::BottomLayer::Leader, groups(:bottom_layer_one))
      member.household_people_ids = [leader.id, other.id]
      member.attributes = leader.attributes.slice(*Person::ADDRESS_ATTRS)

      expect do
        household(member).save
      end.to raise_error 'invalid'
    end

    it 'creates append_to_household version' do
      leader.household_people_ids = [member.id]
      expect do
        household(leader).save
      end.to change { PaperTrail::Version.count }.by(2)
      expect(leader.versions.last.event).to eq 'append_to_household'
      expect(member.versions.last.event).to eq 'append_to_household'
    end

    it 'creates household_update version' do
      leader.household_people_ids = [member.id]
      household(leader).save

      leader.town = 'Greattown'
      expect do
        household(leader).save
      end.to change { PaperTrail::Version.count }.by(2)
      expect(leader.versions.last.event).to eq 'household_updated'
      expect(member.versions.last.event).to eq 'household_updated'
    end

    it 'does not create household_updated version when addesss and people are unchanged' do
      leader.household_people_ids = [member.id]
      household(leader).save
      
      leader.nickname = 'Nik'
      expect do
        household(leader).save
      end.to change { PaperTrail::Version.count }.by(0)
    end

  end

  context '#remove' do
    it 'clears two people household' do
      member.update(household_key: 1)
      leader.update(household_key: 1)

      household(leader).remove
      expect(leader.reload.household_key).to be_nil
      expect(member.reload.household_key).to be_nil
    end

    it 'removes person from 3 people household' do
      other = create(Group::BottomLayer::Leader, groups(:bottom_layer_one))
      member.update(household_key: 1)
      leader.update(household_key: 1)
      other.update(household_key: 1)

      expect do
        household(leader).remove
      end.to change { PaperTrail::Version.count }.by(3)
      expect(leader.reload.household_key).to be_nil
      expect(leader.household_people).to be_empty
      expect(member.reload.household_key).to eq '1'
    end

    it 'creates Papertrail entries at the household deletion' do
      member.update(household_key: 1)
      leader.update(household_key: 1)

      expect do
        household(leader).remove
      end.to change { PaperTrail::Version.count }.by(2)
      expect(leader.versions.last.event).to eq 'remove_from_household'
      expect(member.versions.last.event).to eq 'remove_from_household'
    end

    it 'creates Papertrail entries for removal from 3 people household' do
      other = create(Group::BottomLayer::Leader, groups(:bottom_layer_one))
      member.update(household_key: 1)
      leader.update(household_key: 1)
      other.update(household_key: 1)

      expect do
        household(leader).remove
      end.to change { PaperTrail::Version.count }.by(3)
    end


    it 'does not create Papertrail for remove household, if person does not belong to a household' do
      # test needed, because an unchecked checkbox triggers the remove method
      leader.nickname = 'Nik'
      expect do
        household(leader).remove
      end.to change { PaperTrail::Version.count }.by(0)
    end
  end

end
