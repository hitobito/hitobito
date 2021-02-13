# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# encoding:  utf-8

require "spec_helper"

describe Event::ListsController, type: :controller do
  render_views

  before { sign_in(people(:top_leader)) }

  let(:dom) { Capybara::Node::Simple.new(response.body) }

  let(:dropdown) { dom.find(".nav .dropdown-menu") }
  let(:year) { Date.today.year }
  let(:top_layer) { groups(:top_layer) }
  let(:top_group) { groups(:top_group) }

  context "GET events" do
    let(:tomorrow) { 1.day.from_now }
    let(:table) { dom.find("table") }
    let(:description) { "Impedit rem occaecati quibusdam. Ad voluptatem dolorum hic. Non ad aut repudiandae. " }
    let(:event) { Fabricate(:event, groups: [top_group], description: description) }

    before { event.dates.create(start_at: tomorrow) }

    it "renders title, grouper and selected tab" do
      get :events
      expect(dom).to have_content "Demnächst stattfindende Anlässe"
      expect(dom).to have_content I18n.l(tomorrow, format: :month_year)
      expect(dom.find("body nav .nav-left-section.active > a").text.strip).to eq "Anlässe"
    end

    it "renders event label with link" do
      get :events
      expect(dom.all("table tr a[href]").first[:href]).to eq group_event_path(top_group.id, event.id)
      expect(dom).to have_content "Eventus"
      expect(dom).to have_content "TopGroup"
      expect(dom).to have_content I18n.l(tomorrow, format: :time)
      expect(dom).to have_content "dolorum hi..."
    end

    context "application" do
      let(:link) { dom.all("table a").last }

      it "contains apply button for future events" do
        expect(event.application_possible?).to eq true

        get :events

        expect(link.text.strip).to eq "Anmelden"
        expect(link[:href]).to eq contact_data_group_event_participations_path(event.groups.first,
          event,
          event_role: {
            type: event.participant_types.first.sti_name})
      end
    end
  end

  context "GET courses" do
    context "filter dropdown" do
      before { get :courses }

      let(:items) { dropdown.all("a") }
      let(:first) { items.first }
      let(:middle) { items[1] }
      let(:last) { items.last }

      it "contains links that filter event data" do
        expect(items.size).to eq 5

        expect(items[0].text).to eq "Alle Gruppen"
        expect(items[0][:href]).to eq list_courses_path(year: year)

        expect(items[1].text).to eq top_layer.name
        expect(items[1][:href]).to eq list_courses_path(year: year, group_id: top_layer.id)

        expect(items[2].text).to eq groups(:bottom_layer_one).name
        expect(items[2][:href]).to eq list_courses_path(year: year, group_id: groups(:bottom_layer_one).id)

        expect(items[3].text).to eq groups(:bottom_layer_two).name
        expect(items[3][:href]).to eq list_courses_path(year: year, group_id: groups(:bottom_layer_two).id)

        expect(items[4].text).to eq top_group.name
        expect(items[4][:href]).to eq list_courses_path(year: year, group_id: top_group.id)

        expect(dom.find("body nav .nav-left-section.active > a").text.strip).to eq "Kurse"
      end
    end

    context "yearwise paging" do
      before { get :courses }

      let(:tabs) { dom.find("#content .pagination") }

      it "tabs contain year based pagination" do
        first, last = tabs.all("a")[1], tabs.all("a")[-2]
        expect(first.text).to eq (year - 2).to_s
        expect(first[:href]).to eq list_courses_path(year: year - 2, group_id: people(:top_leader).primary_group.layer_group_id)

        expect(last.text).to eq (year + 1).to_s
        expect(last[:href]).to eq list_courses_path(year: year + 1, group_id: people(:top_leader).primary_group.layer_group_id)
      end
    end

    context "courses content" do
      let(:slk) { event_kinds(:slk) }
      let(:main) { dom.find("#main") }
      let(:slk_ev) { Fabricate(:course, groups: [groups(:top_layer)], kind: event_kinds(:slk), maximum_participants: 20, state: "Geplant") }
      let(:glk_ev) { Fabricate(:course, groups: [groups(:top_group)], kind: event_kinds(:glk), maximum_participants: 20) }

      before do
        set_start_dates(slk_ev, "2009-01-2", "2010-01-2", "2010-01-02", "2011-01-02")
        set_start_dates(glk_ev, "2009-01-2", "2011-01-02")
      end

      it "renders course info within table" do
        get :courses, params: {year: 2010}
        expect(main.find("h2").text.strip).to eq "Scharleiterkurs"
        expect(main.find("table tr:eq(1) td:eq(1) a").text).to eq "Eventus"
        expect(main.find("table tr:eq(1) td:eq(1)").text.strip).to eq "EventusSLK 123 Top"
        expect(main.find("table tr:eq(1) td:eq(1) a")[:href]).to eq group_event_path(slk_ev.groups.first, slk_ev)
        expect(main.find("table tr:eq(1) td:eq(2)").native.to_xml).to eq "<td>02.01.2009 <span class=\"muted\"/><br/>02.01.2010 <span class=\"muted\"/><br/>02.01.2010 <span class=\"muted\"/><br/>02.01.2011 <span class=\"muted\"/></td>"
        expect(main.find("table tr:eq(1) td:eq(3)").text).to eq "0 Anmeldungen für 20 Plätze"
        expect(main.find("table tr:eq(1) td:eq(4)").text).to eq "Geplant"
      end

      it "does not show details for users who cannot manage course" do
        person = Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_one)).person
        sign_in(person)
        get :courses, params: {year: 2010}
        expect(main.find("table tr:eq(1) td:eq(1) a").text).to eq "Eventus"
        expect(main.find("table tr:eq(1) td:eq(1)").text.strip).to eq "EventusSLK 123 Top"
        expect(main.find("table tr:eq(1) td:eq(1) a")[:href]).to eq group_event_path(slk_ev.groups.first, slk_ev)
        expect(main.find("table tr:eq(1) td:eq(2)").native.to_xml).to eq "<td>02.01.2009 <span class=\"muted\"/><br/>02.01.2010 <span class=\"muted\"/><br/>02.01.2010 <span class=\"muted\"/><br/>02.01.2011 <span class=\"muted\"/></td>"
        expect(main).to have_no_selector("table tr:eq(2) td:eq(4)")
      end

      it "groups courses by course type" do
        get :courses, params: {year: 2011}
        expect(main.all("h2")[0].text.strip).to eq "Gruppenleiterkurs"
        expect(main.all("h2")[1].text.strip).to eq "Scharleiterkurs"
      end

      it "filters with group param" do
        get :courses, params: {year: 2011, group_id: glk_ev.group_ids.first}
        expect(main.all("h2").size).to eq 1
      end

      it "filters by year, keeps year in dropdown" do
        get :courses, params: {year: 2010}
        expect(main.all("h2").size).to eq 1
        expect(dropdown.find("li:eq(5) a")[:href]).to eq list_courses_path(year: 2010, group_id: top_group.id)
      end
    end
  end
end
