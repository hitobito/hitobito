# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Group::DeletedPeople do

  let(:group)         { groups(:top_group) }
  let(:person)        { role.person.reload }
  let(:role) do
    Fabricate(Group::TopGroup::Leader.name.to_sym, group: group,
                                                   created_at: DateTime.current - 1.year)
  end
  
  let(:sibling_group)  { groups(:toppers) }
  let(:sibling_person) { sibling_role.person.reload }
  let(:sibling_role) do
    Fabricate(Group::GlobalGroup::Leader.name.to_sym, group: sibling_group,
                                                   created_at: DateTime.current - 1.year)
  end

  context 'when group has people without role' do
    before :each do
      role.destroy
    end

    it 'finds those people' do
      expect(Group::DeletedPeople.deleted_for(group).first).to eq(person)
    end

    it 'doesn\'t find people with new role' do
      Group::TopGroup::Leader.create(person: person, group: group)
      
      expect(person.roles.count).to eq 1
      expect(Group::DeletedPeople.deleted_for(group).count).to eq 0
    end

    it 'finds people from other group in same layer' do
      sibling_role.destroy

      expect(Group::DeletedPeople.deleted_for(group)).to include sibling_person
    end

    it 'finds people from child group' do
      # TODO
    end
  end

  context 'when group has no people without role' do
    it 'returns empty' do
      expect(Group::DeletedPeople.deleted_for(group).count).to eq 0
    end
  end
end
