# encoding: utf-8

#  Copyright (c) 2014, CEVI Regionalverband ZH-SH-GL. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe PeopleSerializer do

  let(:group) { groups(:top_group) }
  let(:list) { group.people.decorate }
  let(:person) { people(:top_leader)}
  let(:multiple) { true }

  let(:controller) { double().as_null_object }

  let(:serializer) do
    ListSerializer.new(list,
                       group: group,
                       multiple_groups: multiple,
                       serializer: PeopleSerializer,
                       controller: controller)
  end

  let(:hash) { serializer.to_hash }


  subject { hash[:people].first }

  before { Fabricate(Group::BottomGroup::Member.name.to_sym, person: person, group: groups(:bottom_group_one_one)) }
  before { Draper::ViewContext.clear! }

  it 'has one entry' do
    hash[:people].should have(1).item
  end

  it 'does not contain login credentials' do
    should_not have_key(:password)
    should_not have_key(:encrypted_password)
    should_not have_key(:authentication_token)
  end

  context 'for one group' do
    let(:multiple) { false }

    it 'contains group url' do
      expect(controller).to receive(:group_person_url).with(group, person, format: :json)
      hash
    end

    it 'contains only roles for this group and their linked group and layer' do
      hash[:linked]['roles'].should have(1).item
      hash[:linked]['groups'].should have(2).items
    end
  end

  context 'for multiple groups' do
    let(:multiple) { true }

    it 'contains group url' do
      expect(controller).to receive(:group_person_url).with(person.primary_group_id, person, format: :json)
      hash
    end

    it 'contains all roles and their linked groups' do
      hash[:linked]['roles'].should have(2).items
      hash[:linked]['groups'].should have(4).items
    end
  end

end