#  Copyright (c) 2012-2018, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Person::HouseholdsController do

  let(:leader) { people(:top_leader) }
  let(:member)    { people(:bottom_member) }
  let(:top_group) { groups(:top_group) }
  let(:person)    { assigns(:person) }
  let(:household) { assigns(:household) }

  context 'as leader' do
    before { sign_in(leader) }

    it 'adds person to new household' do
      get :new, xhr: true, params: parameters(person: leader, other: member)

      expect(person.household_people_ids).to eq [member.id]
      expect(person.town).to eq 'Greattown'
      expect(assigns(:household)).to be_address_changed
      expect(assigns(:household)).to be_people_changed
    end

    it 'adds person to existing household' do
      leader.update(household_key: 1)
      get :new, xhr: true, params: parameters(person: leader, other: member)

      expect(person.household_people_ids).to eq [member.id]
      expect(person.town).to eq 'Greattown'
      expect(assigns(:household)).to be_address_changed
      expect(assigns(:household)).to be_people_changed
    end

    it 'adds person from existing household' do
      member.update(household_key: 1)
      get :new, xhr: true, params: parameters(person: leader, other: member)

      expect(person.household_people_ids).to eq [member.id]
      expect(person.town).to eq 'Greattown'
      expect(assigns(:household)).to be_people_changed
      expect(assigns(:household)).to be_address_changed
    end

    it 'adds person from existing household to existing household' do
      member.update(household_key: 1)
      leader.update(household_key: 2)
      get :new, xhr: true, params: parameters(person: leader, other: member)

      expect(person.household_people_ids).to eq [member.id]
      expect(person.town).to eq 'Greattown'
      expect(assigns(:household)).to be_address_changed
      expect(assigns(:household)).to be_people_changed
    end

    it 'adds two people from an existing household' do
      other = create(Group::TopGroup::Leader, groups(:top_group))
      other.update(household_key: 1)
      member.update(household_key: 1)

      get :new, xhr: true, params: parameters(person: leader, other: member)
      expect(person.household_people_ids).to match_array [other.id, member.id]
      expect(person.town).to eq 'Greattown'
      expect(assigns(:household)).to be_address_changed
      expect(assigns(:household)).to be_people_changed
    end

    it 'adds two people from different existing households' do
      other = create(Group::TopGroup::Leader, groups(:top_group))
      other.update(household_key: 1)
      member.update(household_key: 2)

      get :new, xhr: true, params: parameters(person: leader, other: member, ids: [other.id])
      expect(person.household_people_ids).to match_array [other.id.to_s, member.id]
      expect(person.changes).to include 'address'
    end
  end

  context 'as member with non writable person' do

    before { sign_in(member) }

    it 'adds person to new household' do
      get :new, xhr: true, params: parameters(person: member, other: leader)

      expect(person.household_people_ids).to eq [leader.id]
      expect(person.changes).to include 'address'
    end

    it 'adds person to existing household' do
      member.update(household_key: 1)
      get :new, xhr: true, params: parameters(person: member, other: leader)

      expect(person.household_people_ids).to eq [leader.id]
      expect(person.changes).to include 'address'
    end

    it 'adds person from existing household' do
      member.update(household_key: 1)
      get :new, xhr: true, params: parameters(person: member, other: leader)

      expect(person.household_people_ids).to eq [leader.id]
      expect(person.changes).to include 'address'
    end

    it 'adds person from existing household to existing household' do
      member.update(household_key: 1)
      leader.update(household_key: 2)
      get :new, xhr: true, params: parameters(person: member, other: leader)

      expect(person.household_people_ids).to eq [leader.id]
      expect(person.changes).to include 'address'
    end

    it 'adds two people from an existing household' do
      other = create(Group::TopGroup::Leader, groups(:top_group))
      other.update(household_key: 1)
      leader.update(household_key: 2)

      get :new, xhr: true, params: parameters(person: member, other: leader)
      expect(person.household_people_ids).to match_array [leader.id]
    end
  end

  private

  def parameters(person: , other: , ids: [])
    { group_id: person.groups.first.id,
      person_id: person.id,
      other_person_id: other.id,
      person: person_attrs(ids) }
  end

  def person_attrs(ids)
    { address: '',
      zip_code: '',
      town: '',
      country: '',
      household_people_ids: ids }
  end

  def create(role, group)
    Fabricate(role.name.to_s, group: group).person
  end

end
