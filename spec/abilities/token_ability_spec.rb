# encoding: utf-8

#  Copyright (c) 2018, Pfadibewegung Schliessen. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe TokenAbility do

  subject { ability }
  let(:ability) { TokenAbility.new(token) }

  describe :people do
    let(:token) { service_tokens(:rejected_top_group_token) }

    before do
      token.update(people: true)
    end

    context 'authorized' do

      it 'may index on group' do
        is_expected.to be_able_to(:index_people, token.layer)
      end

      it 'may show on group' do
        person = Fabricate(Group::TopLayer::TopAdmin.name.to_sym, group: token.layer).person
        is_expected.to be_able_to(:show, person)
      end
    end

    context 'unauthorized' do
      it 'may not permit any write actions' do
        person = Fabricate(Group::TopLayer::TopAdmin.name.to_sym, group: token.layer).person
        is_expected.not_to be_able_to(:create, person)
        is_expected.not_to be_able_to(:update, person)
      end

      it 'may not index if disabled' do
        token.update(people: false)
        is_expected.not_to be_able_to(:index_people, token.layer)
      end

      it 'may not show if disabled' do
        token.update(people: false)
        person = Fabricate(Group::TopLayer::TopAdmin.name.to_sym, group: token.layer).person
        is_expected.not_to be_able_to(:show, person)
      end

      it 'may not index on subgroup' do
        is_expected.not_to be_able_to(:index_people,  groups(:top_group))
      end

      it 'may not show in subgroup' do
        person = Fabricate(Group::TopGroup::Member.name.to_sym, group: groups(:top_group)).person
        is_expected.not_to be_able_to(:show, person)
      end
    end
  end

  describe :people_below do
    let(:token) { service_tokens(:rejected_top_group_token) }

    before do
      token.update(people_below: true)
    end

    context 'authorized' do

      it 'may index on group' do
        is_expected.to be_able_to(:index_people, token.layer)
      end

      it 'may index on subgroup' do
        is_expected.to be_able_to(:index_people, groups(:top_group))
      end

      it 'may show on group' do
        person = Fabricate(Group::TopLayer::TopAdmin.name.to_sym, group: token.layer).person
        is_expected.to be_able_to(:show, person)
      end

      it 'may show in subgroup' do
        person = Fabricate(Group::TopGroup::Member.name.to_sym, group: groups(:top_group)).person
        is_expected.to be_able_to(:show, person)
      end

      it 'may restrict visibility for indirect descendants of Group::TopLayer' do
        allow(TokenAbility).to receive(:restrict_descendants).and_return([Group::TopLayer])
        is_expected.to be_able_to(:index_people, groups(:top_group))
        is_expected.not_to be_able_to(:index_people, groups(:bottom_group_one_one))
      end
    end

    context 'unauthorized' do
      it 'may not permit any write actions' do
        person = Fabricate(Group::TopLayer::TopAdmin.name.to_sym, group: token.layer).person
        is_expected.not_to be_able_to(:create, person)
        is_expected.not_to be_able_to(:update, person)
      end

      it 'may not index if disabled' do
        token.update(people_below: false)
        is_expected.not_to be_able_to(:index_people, token.layer)
      end

      it 'may not show if disabled' do
        token.update(people_below: false)
        person = Fabricate(Group::TopLayer::TopAdmin.name.to_sym, group: token.layer).person
        is_expected.not_to be_able_to(:show, person)
      end
    end
  end

  describe :events do
    let(:token) { service_tokens(:rejected_top_group_token) }

    before do
      token.update(events: true)
    end

    context 'authorized' do

      it 'may index on group' do
        is_expected.to be_able_to(:index_events, token.layer)
        is_expected.to be_able_to(:'index_event/courses', token.layer)
      end

      it 'may index on subgroup' do
        is_expected.to be_able_to(:index_events,  groups(:top_group))
        is_expected.to be_able_to(:'index_event/courses',  groups(:top_group))
      end

      it 'may show on group' do
        event = Fabricate(:event, groups: [token.layer])
        is_expected.to be_able_to(:show, event)
      end

      it 'may show in subgroup' do
        event = Fabricate(:event, groups: [groups(:top_group)])
        is_expected.to be_able_to(:show, event)
      end
    end

    context 'unauthorized' do
      it 'may not permit any write actions' do
        event = Fabricate(:event, groups: [token.layer])
        is_expected.not_to be_able_to(:create, event)
        is_expected.not_to be_able_to(:update, event)
      end

      it 'may not index if disabled' do
        token.update(events: false)
        is_expected.not_to be_able_to(:index_events, token.layer)
        is_expected.not_to be_able_to(:'index_event/courses', token.layer)
      end

      it 'may not show if disabled' do
        token.update(events: false)
        event = Fabricate(:event, groups: [groups(:top_group)])
        is_expected.not_to be_able_to(:show, event)
      end
    end
  end

  describe :groups do
    let(:token) { service_tokens(:rejected_top_group_token) }

    before do
      token.update(groups: true)
    end

    context 'authorized' do

      it 'may show layer' do
        is_expected.to be_able_to(:show, token.layer)
      end

      it 'may show subgroup' do
        is_expected.to be_able_to(:show, groups(:top_group))
      end
    end

    context 'unauthorized' do
      it 'may not permit any write actions' do
        is_expected.not_to be_able_to(:create, token.layer)
        is_expected.not_to be_able_to(:update, token.layer)
      end

      it 'may not show if disabled' do
        token.update(groups: false)
        is_expected.not_to be_able_to(:show, token.layer)
      end
    end
  end

end
