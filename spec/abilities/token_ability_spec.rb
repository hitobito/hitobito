# frozen_string_literal: true

#  Copyright (c) 2018, Pfadibewegung Schliessen. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe TokenAbility do

  subject { ability }
  let(:ability) { TokenAbility.new(token) }

  describe :people do
    let(:token) { service_tokens(:rejected_top_layer_token) }

    context 'layer_read' do
      before do
        token.update!(people: true, permission: :layer_read)
      end

      it 'may index on layer people' do
        is_expected.to be_able_to(:index_people, token.layer)
      end

      it 'may show on layer person' do
        person = Fabricate(Group::TopLayer::TopAdmin.name.to_sym, group: token.layer).person
        is_expected.to be_able_to(:show, person)
      end

      it 'may show_full on layer person' do
        person = Fabricate(Group::TopLayer::TopAdmin.name.to_sym, group: token.layer).person
        is_expected.to be_able_to(:show_full, person)
      end

      it 'may not write layer person' do
        person = Fabricate(Group::TopLayer::TopAdmin.name.to_sym, group: token.layer).person
        is_expected.not_to be_able_to(:create, person)
        is_expected.not_to be_able_to(:update, person)
      end

      it 'may not index layer people if disabled' do
        token.update!(people: false)
        is_expected.not_to be_able_to(:index_people, token.layer)
      end

      it 'may not show layer person if disabled' do
        token.update!(people: false)
        person = Fabricate(Group::TopLayer::TopAdmin.name.to_sym, group: token.layer).person
        is_expected.not_to be_able_to(:show, person)
      end

      it 'may not index people on subgroup' do
        is_expected.not_to be_able_to(:index_people,  groups(:top_group))
      end

      it 'may not show or write person in subgroup' do
        person = Fabricate(Group::TopGroup::Member.name.to_sym, group: groups(:top_group)).person
        is_expected.not_to be_able_to(:show, person)
        is_expected.not_to be_able_to(:update, person)
        is_expected.not_to be_able_to(:create, person)
      end
    end

    context 'layer_full' do
      before do
        token.update!(people: true, permission: :layer_full)
      end

      it 'may index on layer people' do
        is_expected.to be_able_to(:index_people, token.layer)
      end

      it 'may show on layer person' do
        person = Fabricate(Group::TopLayer::TopAdmin.name.to_sym, group: token.layer).person
        is_expected.to be_able_to(:show, person)
      end

      it 'may show_full on layer person' do
        person = Fabricate(Group::TopLayer::TopAdmin.name.to_sym, group: token.layer).person
        is_expected.to be_able_to(:show_full, person)
      end

      it 'may write layer person' do
        person = Fabricate(Group::TopLayer::TopAdmin.name.to_sym, group: token.layer).person
        is_expected.to be_able_to(:update, person)
        is_expected.not_to be_able_to(:create, person) # people#create not yet implemented for service token
      end

      it 'may not index layer people if disabled' do
        token.update!(people: false)
        is_expected.not_to be_able_to(:index_people, token.layer)
      end

      it 'may not show or write layer person if disabled' do
        token.update!(people: false)
        person = Fabricate(Group::TopLayer::TopAdmin.name.to_sym, group: token.layer).person
        is_expected.not_to be_able_to(:show, person)
        is_expected.not_to be_able_to(:update, person)
      end

      it 'may not index people on subgroup' do
        is_expected.not_to be_able_to(:index_people,  groups(:top_group))
      end

      it 'may not show or write person in subgroup' do
        person = Fabricate(Group::TopGroup::Member.name.to_sym, group: groups(:top_group)).person
        is_expected.not_to be_able_to(:show, person)
        is_expected.not_to be_able_to(:update, person)
        is_expected.not_to be_able_to(:create, person)
      end
    end

    context 'layer_and_bellow_read' do
      before do
        token.update!(people: true, permission: :layer_and_below_read)
      end

      it 'may index on layer people' do
        is_expected.to be_able_to(:index_people, token.layer)
      end

      it 'may only show on layer person' do
        person = Fabricate(Group::TopLayer::TopAdmin.name.to_sym, group: token.layer).person
        is_expected.to be_able_to(:show, person)
        is_expected.not_to be_able_to(:update, person)
        is_expected.not_to be_able_to(:create, person)
      end

      it 'may show_full on layer person' do
        person = Fabricate(Group::TopLayer::TopAdmin.name.to_sym, group: token.layer).person
        is_expected.to be_able_to(:show_full, person)
      end

      it 'may not index layer people if disabled' do
        token.update!(people: false)
        is_expected.not_to be_able_to(:index_people, token.layer)
      end

      it 'may not show person if disabled' do
        token.update!(people: false)
        person = Fabricate(Group::TopLayer::TopAdmin.name.to_sym, group: token.layer).person
      end

      it 'may index people on subgroup' do
        token.update!(people: false)
        is_expected.not_to be_able_to(:index_people,  groups(:top_group))
      end

      it 'may not index people on subgroup if disabled' do
        token.update!(people: false)
        is_expected.not_to be_able_to(:index_people,  groups(:top_group))
      end

      it 'may only show person in subgroup' do
        person = Fabricate(Group::TopGroup::Member.name.to_sym, group: groups(:top_group)).person
        is_expected.to be_able_to(:show, person)
        is_expected.not_to be_able_to(:update, person)
        is_expected.not_to be_able_to(:create, person)
      end
    end

    context 'layer_and_bellow_full' do
      before do
        token.update!(people: true, permission: :layer_and_below_full)
      end

      it 'may index on layer people' do
        is_expected.to be_able_to(:index_people, token.layer)
      end

      it 'may show and write on layer person' do
        person = Fabricate(Group::TopLayer::TopAdmin.name.to_sym, group: token.layer).person
        is_expected.to be_able_to(:show, person)
        is_expected.to be_able_to(:update, person)
        is_expected.not_to be_able_to(:create, person) # people#create not yet implemented for service token
      end

      it 'may show_full on layer person' do
        person = Fabricate(Group::TopLayer::TopAdmin.name.to_sym, group: token.layer).person
        is_expected.to be_able_to(:show_full, person)
      end

      it 'may not index layer people if disabled' do
        token.update!(people: false)
        is_expected.not_to be_able_to(:index_people, token.layer)
      end

      it 'may not show person if disabled' do
        token.update!(people: false)
        person = Fabricate(Group::TopLayer::TopAdmin.name.to_sym, group: token.layer).person
      end

      it 'may index people on subgroup' do
        token.update!(people: false)
        is_expected.not_to be_able_to(:index_people,  groups(:top_group))
      end

      it 'may not index people on subgroup if disabled' do
        token.update!(people: false)
        is_expected.not_to be_able_to(:index_people,  groups(:top_group))
      end

      it 'may show and write person in subgroup' do
        person = Fabricate(Group::TopGroup::Member.name.to_sym, group: groups(:top_group)).person
        is_expected.to be_able_to(:show, person)
        is_expected.to be_able_to(:update, person)
        is_expected.not_to be_able_to(:create, person) # people#create not yet implemented for service token
      end

      it 'may not show nor write person in subgroup if disabled' do
        token.update!(people: false)
        person = Fabricate(Group::TopGroup::Member.name.to_sym, group: groups(:top_group)).person
        is_expected.not_to be_able_to(:show, person)
        is_expected.not_to be_able_to(:update, person)
        is_expected.not_to be_able_to(:create, person)
      end
    end
  end

  describe :events do
    let(:token) { service_tokens(:rejected_top_layer_token) }

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
    context 'authorized' do
      let(:token) { service_tokens(:permitted_top_layer_token) }

      it 'may show layer' do
        is_expected.to be_able_to(:show, token.layer)
      end

      it 'may show details of layer' do
        is_expected.to be_able_to(:show_details, token.layer)
      end

      it 'may show subgroup' do
        is_expected.to be_able_to(:show, groups(:top_group))
      end

      it 'may show details of subgroup' do
        is_expected.to be_able_to(:show_details, groups(:top_group))
      end

      it 'may show subgroup from other layer' do
        is_expected.to be_able_to(:show, groups(:bottom_layer_one))
      end

      it 'may show details of subgroup from other layer' do
        is_expected.to be_able_to(:show_details, groups(:bottom_layer_one))
      end
    end

    context 'unauthorized' do
      let(:token) { service_tokens(:rejected_top_layer_token) }

      it 'may not permit any write actions' do
        is_expected.not_to be_able_to(:create, token.layer)
        is_expected.not_to be_able_to(:update, token.layer)
      end

      it 'may not show if disabled' do
        is_expected.not_to be_able_to(:show, token.layer)
      end
    end
  end

  describe :invoices do
    context 'authorized' do
      let(:token) { service_tokens(:permitted_top_layer_token) }

      it 'may show' do
        is_expected.to be_able_to(:show, token.layer.invoices.build)
      end

      it 'may show independently if group access' do
        token.update!(groups: false)
        is_expected.to be_able_to(:show, token.layer.invoices.build)
      end

      it 'may index_invoices' do
        is_expected.to be_able_to(:index_invoices, token.layer)
      end

      it 'may index_invoices independently of group access' do
        token.update!(groups: false)
        is_expected.to be_able_to(:index_invoices, token.layer)
      end

      it 'may not index_invoices of sub layer' do
        is_expected.not_to be_able_to(:index_invoices, groups(:bottom_layer_one))
      end

      it 'may not show invoice of sub layer' do
        is_expected.not_to be_able_to(:show, groups(:bottom_layer_one).invoices.build)
      end
    end

    context 'unauthorized' do
      let(:token) { service_tokens(:rejected_top_layer_token) }

      it 'may not show' do
        is_expected.not_to be_able_to(:show, token.layer.invoices.build)
      end

      it 'may not index_invoices' do
        is_expected.not_to be_able_to(:index_invoices, token.layer)
      end

      it 'may not index_invoices of sub layer' do
        is_expected.not_to be_able_to(:index_invoices, groups(:bottom_layer_one))
      end
    end
  end

  describe :event_participations do
    let(:event_participation) { event_participations(:top) }

    context 'authorized' do
      let(:token) { service_tokens(:permitted_top_layer_token) }

      it 'may show' do
        is_expected.to be_able_to(:show, event_participation)
      end

      it 'may show indepently of event and group' do
        token.update(groups: false, events: false)
        is_expected.to be_able_to(:show, event_participation)
      end

      it 'may index_participations' do
        is_expected.to be_able_to(:index_participations, event_participation.event)
      end

      it 'may index_participations idenpently of event and group' do
        token.update(groups: false, events: false)
        is_expected.to be_able_to(:index_participations, event_participation.event)
      end

      it 'may not index_participations of sub layer' do
        event = Event.new(groups: [groups(:bottom_layer_one)])
        is_expected.not_to be_able_to(:index_participations, event)
      end

      it 'may not show participation of sub layer' do
        event = Event.new(groups: [groups(:bottom_layer_one)])
        is_expected.not_to be_able_to(:index_participations, event.participations.build)
      end
    end

    context 'unauthorized' do
      let(:token) { service_tokens(:rejected_top_layer_token) }

      it 'may not show' do
        is_expected.not_to be_able_to(:show, event_participation)
      end

      it 'may not index_participations' do
        is_expected.not_to be_able_to(:index_participations, event_participation.event)
      end

      it 'may not index_participations of sub layer' do
        event = Event.new(groups: [groups(:bottom_layer_one)])
        is_expected.not_to be_able_to(:index_participations, event)
      end
    end
  end

  describe :mailing_lists do
    let(:mailing_list) { mailing_lists(:leaders) }

    context 'authorized' do
      let(:token) { service_tokens(:permitted_top_layer_token) }

      it 'may show' do
        is_expected.to be_able_to(:show, mailing_list)
      end

      it 'may show for list below' do
        list = groups(:top_group).mailing_lists.create!(name: 'list')
        is_expected.to be_able_to(:show, list)
      end

      it 'may not show for list in sub layer' do
        list = groups(:bottom_layer_one).mailing_lists.create!(name: 'list')
        is_expected.not_to be_able_to(:show, list)
      end
    end

    context 'unauthorized' do
      let(:token) { service_tokens(:rejected_top_layer_token) }

      it 'may not show' do
        is_expected.not_to be_able_to(:show, mailing_list)
      end
    end
  end
end
