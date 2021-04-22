# encoding: utf-8

#  Copyright (c) 2021, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# encoding:  utf-8

require 'spec_helper'

describe Events::CoursesController, type: :controller do

  render_views

  before do
    travel_to Time.zone.local(2010,1,1,12)
    sign_in(people(:top_leader))
  end

  let(:dom) { Capybara::Node::Simple.new(response.body) }

  let(:dropdown) { dom.find('.nav .dropdown-menu') }
  let(:top_layer) { groups(:top_layer) }
  let(:top_group) { groups(:top_group) }

  context 'filter dropdown' do
    before { get :index }
    let(:items) { dropdown.all('a') }
    let(:first) { items.first }
    let(:middle) { items[1] }
    let(:last) { items.last }

    it 'contains links that filter event data' do
      expect(items.size).to eq 5

      expect(items[0].text).to eq 'Alle Gruppen'
      expect(items[0][:href]).to eq list_courses_path

      expect(items[1].text).to eq top_layer.name
      expect(items[1][:href]).to eq list_courses_path(group_id: top_layer.id)

      expect(items[2].text).to eq groups(:bottom_layer_one).name
      expect(items[2][:href]).to eq list_courses_path(group_id: groups(:bottom_layer_one).id)

      expect(items[3].text).to eq groups(:bottom_layer_two).name
      expect(items[3][:href]).to eq list_courses_path(group_id: groups(:bottom_layer_two).id)

      expect(items[4].text).to eq top_group.name
      expect(items[4][:href]).to eq list_courses_path(group_id: top_group.id)

      expect(dom.find('body nav .nav-left-section.active > a').text.strip).to eq 'Kurse'
    end
  end

  context 'date filters' do
    before { get :index }
    let(:form) { dom.find('form#date-filter') }

    it 'form contains default date fields' do
      expect(form).to have_css('input.date', count: 2)
      expect(form.all('input.date')[0][:value]).to eq '01.01.2010'
      expect(form.all('input.date')[1][:value]).to eq '01.01.2011'
    end

    it 'date fields contain existing filter values' do
      get :index, params: { filter: { since: '22.04.2021', until: '21.04.2022' } }
      expect(form).to have_css('input.date', count: 2)
      expect(form.all('input.date')[0][:value]).to eq '22.04.2021'
      expect(form.all('input.date')[1][:value]).to eq '21.04.2022'
    end
  end

  context 'courses content' do
    let(:slk) { event_kinds(:slk) }
    let(:main) { dom.find('#main') }
    let(:slk_ev) { Fabricate(:course, groups: [groups(:top_layer)], kind: event_kinds(:slk), maximum_participants: 20, state: 'Geplant') }
    let(:glk_ev) { Fabricate(:course, groups: [groups(:top_layer)], kind: event_kinds(:glk), maximum_participants: 20) }

    before do
      set_start_dates(slk_ev, '2009-01-2', '2010-01-2', '2010-01-02', '2011-01-02')
      set_start_dates(glk_ev, '2009-01-2', '2011-01-02')
    end

    it 'renders course info within table' do
      get :index
      expect(main.find('h2').text.strip).to eq 'Scharleiterkurs'
      expect(main.find('table tr:eq(1) td:eq(1) a').text).to eq 'Eventus'
      expect(main.find('table tr:eq(1) td:eq(1)').text.strip).to eq 'EventusSLK 123 Top'
      expect(main.find('table tr:eq(1) td:eq(1) a')[:href]).to eq group_event_path(slk_ev.groups.first, slk_ev)
      expect(main.find('table tr:eq(1) td:eq(2)').native.to_xml).to eq "<td>02.01.2009 <span class=\"muted\"/><br/>02.01.2010 <span class=\"muted\"/><br/>02.01.2010 <span class=\"muted\"/><br/>02.01.2011 <span class=\"muted\"/></td>"
      expect(main.find('table tr:eq(1) td:eq(3)').text).to eq '0 Anmeldungen für 20 Plätze'
      expect(main.find('table tr:eq(1) td:eq(4)').text).to eq 'Geplant'
    end

    it 'does not show details for users who cannot manage course' do
      person = Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_one)).person
      sign_in(person)
      get :index
      expect(main.find('table tr:eq(1) td:eq(1) a').text).to eq 'Eventus'
      expect(main.find('table tr:eq(1) td:eq(1)').text.strip).to eq 'EventusSLK 123 Top'
      expect(main.find('table tr:eq(1) td:eq(1) a')[:href]).to eq group_event_path(slk_ev.groups.first, slk_ev)
      expect(main.find('table tr:eq(1) td:eq(2)').native.to_xml).to eq "<td>02.01.2009 <span class=\"muted\"/><br/>02.01.2010 <span class=\"muted\"/><br/>02.01.2010 <span class=\"muted\"/><br/>02.01.2011 <span class=\"muted\"/></td>"
      expect(main).to have_no_selector('table tr:eq(2) td:eq(4)')
    end

    it 'groups courses by course type' do
      get :index, params: { filter: { until: '01.01.2012' } }
      expect(main.all('h2').size).to eq 2
      expect(main.all('h2')[0].text.strip).to eq 'Gruppenleiterkurs'
      expect(main.all('h2')[1].text.strip).to eq 'Scharleiterkurs'
    end

    it 'filters with group param' do
      get :index, params: { group_id: glk_ev.group_ids.first }
      expect(main.all('h2').size).to eq 1
    end

    it 'filters by date, keeps date in dropdown' do
      get :index, params: { filter: { since: '01.01.2010', until: '01.01.2011' } }
      expect(main.all('h2').size).to eq 1
      expect(dropdown.find('li:eq(5) a')[:href]).to eq list_courses_path(filter: { since: '01.01.2010', until: '01.01.2011' }, group_id: top_group.id)
    end

  end

end
