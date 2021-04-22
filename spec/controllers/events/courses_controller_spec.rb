# encoding: utf-8

#  Copyright (c) 2021, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Events::CoursesController do
  render_views
  before do
    travel_to Time.zone.local(2020,1,1,12)
    sign_in(person)
  end
  let(:person) { people(:bottom_member) }

  context 'filters by date' do

    it 'defaults to courses a year from today' do
      get :index
      expect(assigns(:since_date)).to eq '01.01.2020'
      expect(assigns(:until_date)).to eq '01.01.2021'
    end

    it 'reads since date from params, populates vars' do
      get :index, params: { filter: { since: '03.04.2021' } }
      expect(assigns(:since_date)).to eq '03.04.2021'
      expect(assigns(:until_date)).to eq '03.04.2022'
    end

    it 'reads until date from params, populates vars' do
      get :index, params: { filter: { until: '03.04.2021' } }
      expect(assigns(:since_date)).to eq '01.01.2020'
      expect(assigns(:until_date)).to eq '03.04.2021'
    end

    it 'reads both dates from params, populates vars' do
      get :index, params: { filter: { since: '02.06.2020', until: '03.04.2021' } }
      expect(assigns(:since_date)).to eq '02.06.2020'
      expect(assigns(:until_date)).to eq '03.04.2021'
    end

    it 'groups by course kind' do
      course = Fabricate(:course, groups: [groups(:top_layer)], kind: event_kinds(:slk), maximum_participants: 20)
      course.dates.build(start_at: '02.01.2020')
      course.save
      get :index
      expect(assigns(:grouped_events).keys).to eq ['Scharleiterkurs']
    end
  end

  context 'filter per group' do
    before { sign_in(people(:top_leader)) }

    it 'defaults to layer of primary group' do
      get :index
      expect(assigns(:group_id)).to eq groups(:top_group).layer_group_id
    end

    it 'can be set via param' do
      get :index, params: { group_id: groups(:top_layer).id }
      expect(assigns(:group_id)).to eq groups(:top_layer).id
    end
  end

  context 'finds course offerer' do
    it 'via primary group' do
      sign_in(people(:top_leader))
      get :index
      expect(controller.send(:course_group_from_primary_layer)).to eq groups(:top_layer)
    end

    it 'via hierarchy' do
      group = groups(:bottom_group_one_one)
      user = Fabricate(Group::BottomGroup::Leader.name.to_s, label: 'foo', group: group).person
      sign_in(user)
      get :index
      expect(controller.send(:course_group_from_hierarchy).id).to eq groups(:bottom_layer_one).id
    end
  end

  context 'exports to csv' do
    let(:rows) { response.body.split("\n") }
    let(:course) { Fabricate(:course) }
    before { Fabricate(:event_date, event: course)  }

    it 'renders csv headers' do
      allow(controller).to receive_messages(current_user: people(:root))
      get :index, format: :csv
      expect(response).to be_successful
      expect(rows.first).to match(/^Name;Organisatoren;Kursnummer;Kursart;.*;Anzahl Anmeldungen$/)
      expect(rows.size).to eq(2)
    end
  end

  context 'without kind_id' do
    before { Event::Course.used_attributes -= [:kind_id] }

    it 'groups by month' do
      course = Fabricate(:course, groups: [groups(:top_layer)], kind: event_kinds(:slk), maximum_participants: 20)
      course.dates.clear
      course.dates.build(start_at: '02.03.2020')
      course.save
      get :index
      expect(assigns(:grouped_events).keys).to eq(['März 2020'])
    end

    after { Event::Course.used_attributes += [:kind_id] }
  end

  context 'booking info' do
    before do
      course = Fabricate(:course, display_booking_info: false)
      Fabricate(:event_date, event: course, start_at: Date.new(2012, 1, 23))
    end

    it 'is visible for manager' do
      sign_in(people(:top_leader))
      get :index, params: { filter: { since: '01.01.2012' } }
      expect(response.body).to have_selector('tbody tr', count: 2)
      expect(response.body).to have_selector('tbody tr:nth-child(1) td:nth-child(3)',
                                             text: '0 Anmeldungen')
      expect(response.body).to have_selector('tbody tr:nth-child(2) td:nth-child(3)',
                                             text: '0 Anmeldungen')
    end

    it 'is only visible for member where allowed by course' do
      sign_in(people(:bottom_member))
      get :index, params: { filter: { since: '01.01.2012' } }
      expect(response.body).to have_selector('tbody tr', count: 2)
      expect(response.body).not_to have_selector('tbody tr:nth-child(1) td:nth-child(3)',
                                                 text: '0 Anmeldungen')
      expect(response.body).to have_selector('tbody tr:nth-child(2) td:nth-child(3)',
                                             text: '0 Anmeldungen')
    end

  end

end
