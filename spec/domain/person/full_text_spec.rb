# encoding: utf-8

#  Copyright (c) 2012-2016, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Person::FullText do

  let(:top_leader) { people(:top_leader) }

  context 'admin' do

    it 'may get deleted people' do
      other = Fabricate(Group::TopGroup::Secretary.name.to_sym, group: groups(:top_group))
      other.update(created_at: Time.now - 1.year)
      other.destroy
      expect(Person::FullText.load_accessible_deleted_people_ids(top_leader)).to include(other.person.id)
    end
  end

end
