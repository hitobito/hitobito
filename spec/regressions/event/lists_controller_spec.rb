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

  context "GET events" do
    let(:tomorrow) { 1.day.from_now }
    let(:table) { dom.find('table') }
    let(:description) { "Impedit rem occaecati quibusdam. Ad voluptatem dolorum hic. Non ad aut repudiandae. " }
    let(:event) { Fabricate(:event, group: top_group, description: description) }
    before  { event.dates.create(start_at: tomorrow) }

    it "renders title, grouper and selected tab" do
      get :events
      dom.should have_content "Demnächst stattfindende Anlässe"
      dom.should have_content I18n.l(tomorrow, format: :month_year)
      dom.find('body nav .active').text.should eq 'Kurse/Anlässe'
      dom.find('#content .nav .active').text.should eq 'Anlässe'
    end

    it "renders event label with link" do
      get :events
      dom.find('table a')[:href].should eq group_event_path(top_group.id, event.id)
      dom.should have_content 'Eventus'
      dom.should have_content 'TopGroup'
      dom.should have_content I18n.l(tomorrow, format: :time)
      dom.should have_content "dolorum hi..."
    end
  end

  context "GET courses" do

    context "title" do
      let(:title_text) { dom.find('#content h1').text }

      it "defaults to courses within current users group" do
        get :courses
        title_text.should eq prefixed(top_group.name)
      end

      it "changes when showing all groups" do
        get :courses, group: 0, year: 2012
        title_text.should eq prefixed('allen Gruppen')
      end

      it "changes when showing specific groups" do
        get :courses, group: top_layer.id, year: 2012
        title_text.should eq prefixed(top_layer.name)
      end
    end

    context "filter dropdown" do
      before { get :courses }
      let(:items) { dropdown.all('a') }
      let(:first) { items.first }  
      let(:middle) { items[1] }
      let(:last) { items.last}

      it "contains links that filter event data" do
        items.size.should eq 3

        first.text.should eq 'Alle Gruppen'
        first[:href].should eq list_courses_path(year: year)

        middle.text.should eq top_layer.name
        middle[:href].should eq list_courses_path(year: year, group: top_layer.id)

        last.text.should eq top_group.name
        last[:href].should eq list_courses_path(year: year, group: top_group.id)
      end
    end


    context "yearwise paging" do
      before { get :courses }
      let(:tabs) { dom.find('#content .pagination') }

      it "tabs contain year based pagination" do
        first, last = tabs.all('a').first, tabs.all('a').last
        first.text.should eq (year - 3).to_s
        first[:href].should eq list_courses_path(year: year - 3, group: top_group.id)

        last.text.should eq (year + 1).to_s
        last[:href].should eq list_courses_path(year: year + 1, group: top_group.id)
      end
    end


    context "courses content" do
      let(:slk) { event_kinds(:slk)}
      let(:main) { dom.find("#main") }
      let(:slk_ev) { Fabricate(:course, group: groups(:top_layer), kind: event_kinds(:slk), maximum_participants: 20, state: 'Geplant' ) }
      let(:glk_ev) { Fabricate(:course, group: groups(:top_group), kind: event_kinds(:glk), maximum_participants: 20 ) }

      before do 
        set_start_dates(slk_ev, "2009-01-2", "2010-01-2", "2010-01-02", "2011-01-02") 
        set_start_dates(glk_ev, "2009-01-2", "2011-01-02") 
      end

      it "renders course info within table" do
        get :courses, year: 2010
        main.find('h2').text.should eq 'Scharleiterkurs'
        main.find('table tr:eq(2) td:eq(1) a').text.should eq 'Eventus'
        main.find('table tr:eq(2) td:eq(1)').text.strip.should eq "EventusSLK  Top"
        main.find('table tr:eq(2) td:eq(1) a')[:href].should eq group_event_path(slk_ev.group, slk_ev)
        main.find('table tr:eq(2) td:eq(2)').native.to_xml.should eq "<td>02.01.2009 <span class=\"muted\"/><br/>02.01.2010 <span class=\"muted\"/><br/>02.01.2010 <span class=\"muted\"/><br/>02.01.2011 <span class=\"muted\"/></td>"
        main.find('table tr:eq(2) td:eq(3)').text.should eq "0 von 20"
        main.find('table tr:eq(2) td:eq(4)').text.should eq 'Geplant'
      end

      it "does not show details for users who cannot manage course" do
        person = Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_one)).person
        sign_in(person)
        get :courses, year: 2010
        main.find('table tr:eq(2) td:eq(1) a').text.should eq 'Eventus'
        main.find('table tr:eq(2) td:eq(1)').text.strip.should eq "EventusSLK  Top"
        main.find('table tr:eq(2) td:eq(1) a')[:href].should eq group_event_path(slk_ev.group, slk_ev)
        main.find('table tr:eq(2) td:eq(2)').native.to_xml.should eq "<td>02.01.2009 <span class=\"muted\"/><br/>02.01.2010 <span class=\"muted\"/><br/>02.01.2010 <span class=\"muted\"/><br/>02.01.2011 <span class=\"muted\"/></td>"
        expect { main.find('table tr:eq(2) td:eq(4)') }.to raise_error
      end

      it "groups courses by course type" do
        get :courses, year: 2011
        main.all('h2').size.should eq 2
        main.find('tr:eq(1) h2').text.should eq 'Gruppenleiterkurs'
        main.find('tr:eq(3) h2').text.should eq 'Scharleiterkurs'
      end

      it "filters with group param" do
        get :courses, year: 2011, group: glk_ev.group.id
        main.all('h2').size.should eq 1
      end

      it "filters by year, keeps year in dropdown" do
        get :courses, year: 2010
        main.all('h2').size.should eq 1
        dropdown.find('li:eq(3) a')[:href].should eq list_courses_path(year: 2010, group: top_group.id)
      end

    end

    def prefixed(text)
      "Verfügbare Kurse in #{text}"
    end
  end
end


