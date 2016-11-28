# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Group::DeletedPeople do

  let(:person) { role.person.reload }
  subject { person }

  context 'group has deleted people' do
    let(:role) { Fabricate(Group::TopGroup::Leader.name.to_sym, group: groups(:top_group)) }

    it 'found deleted people' do
      group = Group.find(person.primary_group_id)
      deletion_date = DateTime.current
      role.update(created_at: deletion_date - 30.days)
      role.destroy
      expect(Group::DeletedPeople.deleted_for(group).first).to eq(person)
    end

  end
end
