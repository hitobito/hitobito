# frozen_string_literal: true

#  Copyright (c) 2012-2023, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Person::QueryHouseholdController do

  let(:bottom_member) { people(:bottom_member) }
  let(:top_group) { groups(:top_group) }
  it 'does not find person if its not writable' do
    sign_in(people(:bottom_member))
    person = Fabricate(:person, first_name: 'Pascal')
    Fabricate(Group::TopGroup::Member.name.to_s, person: person, group: top_group)
    get :index, params: { q: 'pas', person_id: bottom_member.id }
    expect(response.body).not_to match(/Pascal/)
  end

  it 'finds person if its writable' do
    sign_in(people(:top_leader))
    person = Fabricate(:person, first_name: 'Pascal')
    Fabricate(Group::TopGroup::Member.name.to_s, person: person, group: top_group)
    get :index, params: { q: 'pas', person_id: bottom_member.id }
    expect(response.body).to match(/Pascal/)
  end

  it 'finds person if it has the same address' do
    sign_in(people(:bottom_member))
    person = Fabricate(:person, first_name: 'Pascal', street: 'Greatstreet', housenumber: 345,
                                zip_code: '3456', town: 'Greattown')
    Fabricate(Group::TopGroup::Member.name.to_s, person: person, group: top_group)
    get :index, params: { q: 'pas', person_id: bottom_member.id }
    expect(response.body).to match(/Pascal/)
  end

  it 'finds logged in user' do
    sign_in(bottom_member)
    person = bottom_member
    Fabricate(Group::TopGroup::Member.name.to_s, person: person, group: groups(:top_group))
    get :index,
        params: { q: "#{person.first_name} #{person.last_name}", person_id: bottom_member.id }
    expect(response.body).to match(Regexp.new("#{person.first_name} #{person.last_name}"))
  end

end
