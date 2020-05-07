# encoding: utf-8

#  Copyright (c) 2012-2015, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Person::HistoryController, type: :controller do

  render_views

  let(:top_leader) { people(:top_leader) }
  let(:top_group) { groups(:top_group) }
  let(:bottom_group) { groups(:bottom_group_one_one) }
  let(:test_entry) { top_leader }
  let(:other) { Fabricate(Group::TopGroup::Member.name.to_sym, group: top_group).person }
  let(:dom) { Capybara::Node::Simple.new(response.body) }

  before { sign_in(top_leader) }

  describe '#index' do
    let(:params) { { group_id: top_group.id, id: other.id } }

    it 'list current role and group' do
      get :index, params: params
      expect(dom.all('table tbody tr').size).to eq 1
      role_row = dom.find('table tbody tr:eq(1)')
      expect(role_row.find('td:eq(1) a:eq(2)').text).to eq 'TopGroup'
      expect(role_row.find('td:eq(2)').text.strip).to eq 'Member'
      expect(role_row.find('td:eq(3)').text).to be_present
      expect(role_row.find('td:eq(4)').text).not_to be_present
    end

    it 'lists past roles' do
      role = Fabricate(Group::BottomGroup::Member.name.to_sym, group: bottom_group, person: other)
      role.created_at = Time.zone.now - 2.years
      role.destroy
      get :index, params: params
      expect(dom.all('table tbody tr').size).to eq 2
      role_row = dom.find('table tbody tr:eq(1)')
      expect(role_row.find('td:eq(1) a:eq(2)').text).to eq 'Group 11'
      expect(role_row.find('td:eq(2)').text.strip).to eq 'Member'
      expect(role_row.find('td:eq(3)').text).to be_present
      expect(role_row.find('td:eq(4)').text).to be_present
    end

    it 'lists roles in other groups' do
      Fabricate(Group::TopGroup::Member.name.to_sym, group: top_group, person: other)
      get :index, params: params
      expect(dom.all('table tbody tr').size).to eq 2
      role_row = dom.find('table tbody tr:eq(2)')
      expect(role_row.find('td:eq(1) a:eq(2)').text).to eq 'TopGroup'
      expect(role_row.find('td:eq(4)').text).not_to be_present
    end

    it 'lists past roles in other groups' do
      role = Fabricate(Group::TopGroup::Member.name.to_sym, group: top_group, person: other)
      role.created_at = Time.zone.now - 2.years
      role.destroy
      get :index, params: params
      expect(dom.all('table tbody tr').size).to eq 2
      role_row = dom.find('table tbody tr:eq(2)')
      expect(role_row.find('td:eq(1) a:eq(2)').text).to eq 'TopGroup'
      expect(role_row.find('td:eq(4)').text).to be_present
    end

    it "lists person's events" do
      course1 = Fabricate(:course, groups: [groups(:top_layer)], kind: event_kinds(:slk))
      event1 = Fabricate(:event, groups: [groups(:top_layer)])
      event2 = Fabricate(:event, groups: [groups(:top_layer)])
      [course1, event1, event2].each do |event|
        Fabricate(:event_role, participation: Fabricate(:event_participation, person: people(:top_leader), event: event), type: 'Event::Role::Leader')
      end

      get :index, params: { group_id: top_group.id, id: top_leader.id }

      events = dom.find('events')

      expect(events).to have_selector('h2', text: 'Kurse')
      expect(events).to have_selector('h2', text: 'Anlässe')

      expect(events.all('tr td a').size).to eq 3
    end
  end

end
