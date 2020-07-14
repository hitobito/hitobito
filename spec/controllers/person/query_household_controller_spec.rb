# encoding: utf-8

#  Copyright (c) 2012-2015, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Person::QueryHouseholdController do

  let(:bottom_member) { people(:bottom_member) }

  it 'does not find person if its not writable' do
    sign_in(people(:bottom_member))
    person = Fabricate(:person, first_name: 'Pascal')
    Fabricate(Group::TopGroup::Member.name.to_s, person: person, group: groups(:top_group))
    get :index, params: { q: 'pas', person_id: bottom_member.id }
    expect(response.body).not_to match(/Pascal/)
  end

  it 'finds person if its writable' do
    sign_in(people(:top_leader))
    person = Fabricate(:person, first_name: 'Pascal')
    Fabricate(Group::TopGroup::Member.name.to_s, person: person, group: groups(:top_group))
    get :index, params: { q: 'pas', person_id: bottom_member.id }
    expect(response.body).to match(/Pascal/)
  end

  it 'finds person if it has the same address' do
    sign_in(people(:bottom_member))
    person = Fabricate(:person, first_name: 'Pascal', town: 'Greattown', zip_code: '3456', address: 'Greatstreet 345')
    Fabricate(Group::TopGroup::Member.name.to_s, person: person, group: groups(:top_group))
    get :index, params: { q: 'pas', person_id: bottom_member.id }
    expect(response.body).to match(/Pascal/)
  end

  it 'finds person if edited person only matches part of address ' do
    sign_in(people(:bottom_member))
    people(:bottom_member).update(zip_code: nil, address: nil)
    person = Fabricate(:person, first_name: 'Pascal', town: 'Greattown', zip_code: '3456', address: 'Greatstreet 345')
    Fabricate(Group::TopGroup::Member.name.to_s, person: person, group: groups(:top_group))
    get :index, params: { q: 'pas', person_id: bottom_member.id }
    expect(response.body).to match(/Pascal/)
  end

end
