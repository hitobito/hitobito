# encoding: utf-8
# frozen_string_literal: true

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Subscriber::EventController do

  before { sign_in(person) }

  let(:now) { Time.zone.now }
  let(:group) { groups(:top_group) }
  let(:person) { people(:top_leader) }
  let(:list) { Fabricate(:mailing_list, group: group) }

  context 'GET query' do
    subject { response.body }

    context 'returns event and group name' do
      before do
        create_event('event', now)

        get :query, params: { q: 'event', group_id: group.id, mailing_list_id: list.id }
      end

      it { is_expected.to match(/event \(TopGroup\)/) }
    end

    context 'lists events from previous year onwards' do
      before do
        create_event('event now', now)
        create_event('event later', now + 5.minutes)
        create_event('event last_year', now - 1.year)
        create_event('event two_years_ago', now - 5.years)

        get :query, params: { q: 'event', group_id: group.id, mailing_list_id: list.id }
      end

      it { is_expected.to match(/now/) }
      it { is_expected.to match(/later/) }
      it { is_expected.to match(/last_year/) }
      it { is_expected.not_to match(/two_years_ago/) }
    end

    context 'list only events from self, sister and descendants' do
      let(:group) { groups(:bottom_layer_one) }
      let(:person) { Fabricate(Group::BottomLayer::Leader.name.to_s, group: group).person }

      before do
        create_event('event', now)
        create_event('event', now, groups(:bottom_group_one_one))
        create_event('event', now, groups(:bottom_group_two_one))
        create_event('event', now, groups(:bottom_layer_two))
        create_event('event', now, groups(:top_group))

        get :query, params: { q: 'event', group_id: group.id, mailing_list_id: list.id }
      end

      it { is_expected.to match(%r{#{groups(:bottom_group_one_one).name}}) }
      it { is_expected.not_to match(%r{#{groups(:bottom_group_two_one).name}}) }
      it { is_expected.not_to match(%r{#{groups(:bottom_layer_two).name}}) }
      it { is_expected.not_to match(%r{#{groups(:top_group).name}}) }
    end

    context 'finds by group name' do
      before do
        create_event('foobar', now)

        get :query, params: { q: 'Top Group', group_id: group.id, mailing_list_id: list.id }
      end

      it { is_expected.to match(/foobar/) }
    end

    context 'finds by event kind' do
      before do
        course = Fabricate(:course, name: 'foobar', groups: [group])
        Fabricate(:event_date, event: course, start_at: now)

        get :query, params: { q: 'Scharleiter', group_id: group.id, mailing_list_id: list.id }
      end

      it { is_expected.to match(/foobar/) }
    end
  end

  context 'POST create' do

    let(:event) { create_event('event', now) }

    it 'adds subscription' do
      expect do
        post :create, params: {
                        group_id: group.id,
                        mailing_list_id: list.id,
                        subscription: { subscriber_id: event.id }
                      }
      end.to change(Subscription, :count).by(1)

      is_expected.to redirect_to(group_mailing_list_subscriptions_path(list.group_id, list.id))
    end

    it 'without subscriber_id replaces error' do
      post :create, params: {
                      group_id: group.id,
                      mailing_list_id: list.id
                    }

      is_expected.to render_template('crud/new')
      expect(assigns(:subscription).errors.size).to eq(1)
      expect(assigns(:subscription).errors[:base]).to eq ['Anlass muss ausgewählt werden']
    end

    it 'duplicated subscription replaces error' do
      subscription = list.subscriptions.build
      subscription.update_attribute(:subscriber, event)

      expect do
        post :create, params: {
                        group_id: group.id,
                        mailing_list_id: list.id,
                        subscription: { subscriber_id: event.id }
                      }
      end.not_to change(Subscription, :count)

      is_expected.to render_template('crud/new')
      expect(assigns(:subscription).errors.size).to eq(1)
      expect(assigns(:subscription).errors[:base]).to eq ['Anlass wurde bereits hinzugefügt']
    end
  end


  def create_event(name, start_at, event_group = group)
    event = Fabricate(:event, name: name, groups: [event_group])
    event.dates.first.update_attribute(:start_at, start_at)
    event
  end

end
