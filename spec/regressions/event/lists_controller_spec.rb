# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# encoding:  utf-8

require 'spec_helper'

describe Event::ListsController, type: :controller do

  render_views

  before { sign_in(people(:top_leader)) }

  let(:dom) { Capybara::Node::Simple.new(response.body) }

  let(:dropdown) { dom.find('.dropdown-menu') }
  let(:year) { Date.today.year }
  let(:top_layer) { groups(:top_layer) }
  let(:top_group) { groups(:top_group) }

  context 'GET events' do
    let(:tomorrow) { 1.day.from_now }
    let(:table) { dom.find('table') }
    let(:description) { 'Impedit rem occaecati quibusdam. Ad voluptatem dolorum hic. Non ad aut repudiandae. ' }
    let(:event) { Fabricate(:event, groups: [top_group], description: description) }
    before  { event.dates.create(start_at: tomorrow) }

    it 'renders title, grouper and selected tab' do
      get :events
      dom.should have_content 'Demnächst stattfindende Anlässe'
      dom.should have_content I18n.l(tomorrow, format: :month_year)
      dom.find('body nav .active').text.should eq 'Anlässe'
    end

    it 'renders event label with link' do
      get :events
      dom.all('table tr a[href]').first[:href].should eq group_event_path(top_group.id, event.id)
      dom.should have_content 'Eventus'
      dom.should have_content 'TopGroup'
      dom.should have_content I18n.l(tomorrow, format: :time)
      dom.should have_content 'dolorum hi...'
    end

    context 'application' do
      let(:link) { dom.all('table a').last }
      it 'contains apply button for future events' do
        event.application_possible?.should eq true

        get :events

        link.text.strip.should eq 'Anmelden'
        link[:href].should eq new_group_event_participation_path(event.groups.first,
                                                                 event,
                                                                 event_role: {
                                                                   type: event.class.participant_types.first.sti_name})
      end
    end
  end

  context 'GET courses' do

    context 'filter dropdown' do
      before { get :courses }
      let(:items) { dropdown.all('a') }
      let(:first) { items.first }
      let(:middle) { items[1] }
      let(:last) { items.last }

      it 'contains links that filter event data' do
        items.size.should eq 5

        items[0].text.should eq 'Alle Gruppen'
        items[0][:href].should eq list_courses_path(year: year)

        items[1].text.should eq top_layer.name
        items[1][:href].should eq list_courses_path(year: year, group_id: top_layer.id)

        items[2].text.should eq groups(:bottom_layer_one).name
        items[2][:href].should eq list_courses_path(year: year, group_id: groups(:bottom_layer_one).id)

        items[3].text.should eq groups(:bottom_layer_two).name
        items[3][:href].should eq list_courses_path(year: year, group_id: groups(:bottom_layer_two).id)

        items[4].text.should eq top_group.name
        items[4][:href].should eq list_courses_path(year: year, group_id: top_group.id)

        dom.find('body nav .active').text.should eq 'Kurse'
      end
    end

    context 'yearwise paging' do
      before { get :courses }
      let(:tabs) { dom.find('#content .pagination') }

      it 'tabs contain year based pagination' do
        first, last = tabs.all('a')[1], tabs.all('a')[-2]
        first.text.should eq (year - 2).to_s
        first[:href].should eq list_courses_path(year: year - 2, group_id: top_group.id)

        last.text.should eq (year + 1).to_s
        last[:href].should eq list_courses_path(year: year + 1, group_id: top_group.id)
      end
    end

    context 'courses content' do
      let(:slk) { event_kinds(:slk) }
      let(:main) { dom.find('#main') }
      let(:slk_ev) { Fabricate(:course, groups: [groups(:top_layer)], kind: event_kinds(:slk), maximum_participants: 20, state: 'Geplant') }
      let(:glk_ev) { Fabricate(:course, groups: [groups(:top_group)], kind: event_kinds(:glk), maximum_participants: 20) }

      before do
        set_start_dates(slk_ev, '2009-01-2', '2010-01-2', '2010-01-02', '2011-01-02')
        set_start_dates(glk_ev, '2009-01-2', '2011-01-02')
      end

      it 'renders course info within table' do
        get :courses, year: 2010
        main.find('h2').text.strip.should eq 'Scharleiterkurs'
        main.find('table tr:eq(1) td:eq(1) a').text.should eq 'Eventus'
        main.find('table tr:eq(1) td:eq(1)').text.strip.should eq 'EventusSLK  Top'
        main.find('table tr:eq(1) td:eq(1) a')[:href].should eq group_event_path(slk_ev.groups.first, slk_ev)
        main.find('table tr:eq(1) td:eq(2)').native.to_xml.should eq "<td>02.01.2009 <span class=\"muted\"/><br/>02.01.2010 <span class=\"muted\"/><br/>02.01.2010 <span class=\"muted\"/><br/>02.01.2011 <span class=\"muted\"/></td>"
        main.find('table tr:eq(1) td:eq(3)').text.should eq '0 Anmeldungen für 20 Plätze'
        main.find('table tr:eq(1) td:eq(4)').text.should eq 'Geplant'
      end

      it 'does not show details for users who cannot manage course' do
        person = Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_one)).person
        sign_in(person)
        get :courses, year: 2010
        main.find('table tr:eq(1) td:eq(1) a').text.should eq 'Eventus'
        main.find('table tr:eq(1) td:eq(1)').text.strip.should eq 'EventusSLK  Top'
        main.find('table tr:eq(1) td:eq(1) a')[:href].should eq group_event_path(slk_ev.groups.first, slk_ev)
        main.find('table tr:eq(1) td:eq(2)').native.to_xml.should eq "<td>02.01.2009 <span class=\"muted\"/><br/>02.01.2010 <span class=\"muted\"/><br/>02.01.2010 <span class=\"muted\"/><br/>02.01.2011 <span class=\"muted\"/></td>"
        expect { main.find('table tr:eq(2) td:eq(4)') }.to raise_error
      end

      it 'groups courses by course type' do
        get :courses, year: 2011
        main.all('h2')[0].text.strip.should eq 'Gruppenleiterkurs'
        main.all('h2')[1].text.strip.should eq 'Scharleiterkurs'
      end

      it 'filters with group param' do
        get :courses, year: 2011, group_id: glk_ev.group_ids.first
        main.all('h2').size.should eq 1
      end

      it 'filters by year, keeps year in dropdown' do
        get :courses, year: 2010
        main.all('h2').size.should eq 1
        dropdown.find('li:eq(5) a')[:href].should eq list_courses_path(year: 2010, group_id: top_group.id)
      end

    end

  end
end
