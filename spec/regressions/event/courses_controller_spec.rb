# encoding:  utf-8

require 'spec_helper'

describe Event::CoursesController, type: :controller do

  render_views

  before { sign_in(people(:top_leader)) } 

  let(:dom) { Capybara::Node::Simple.new(response.body) }

  let(:dropdown) { dom.find('.dropdown-menu') }
  let(:year) { Date.today.year }
  let(:top_layer) { groups(:top_layer) }
  let(:top_group) { groups(:top_group) }

  context "GET index" do
    let(:title_text) { dom.find('#content h1').text }

    it "list toplevel group with course per default" do
      get :index
      title_text.should eq prefixed(top_group.name)
    end

    it "list all groups only with specific year" do
      get :index, group: 0, year: 2012
      title_text.should eq prefixed('allen Gruppen')
    end

    it "list specify groups only with specific year" do
      get :index, group: top_layer.id, year: 2012
      title_text.should eq prefixed(top_layer.name)
    end


    def prefixed(text)
      "Verfügbare Kurse in #{text}"
    end
  end

  context "GET index, shows dropdown" do
    before { get :index }
    let(:items) { dropdown.all('a') }
    let(:first) { items.first }  
    let(:middle) { items[1] }
    let(:last) { items.last}

    it "contains links that filter event data" do
      items.size.should eq 3

      first.text.should eq 'Alle Gruppen'
      first[:href].should eq event_courses_path(year: year)

      middle.text.should eq top_layer.name
      middle[:href].should eq event_courses_path(year: year, group: top_layer.id)

      last.text.should eq top_group.name
      last[:href].should eq event_courses_path(year: year, group: top_group.id)
    end
  end

  context "GET index, shows yearwise paging" do
    before { get :index }
    let(:tabs) { dom.find('#content .pagination') }

    it "tabs contain year based pagination" do
      first, last = tabs.all('a').first, tabs.all('a').last
      first.text.should eq (year - 2).to_s
      first[:href].should eq event_courses_path(year: year - 2, group: top_group.id)

      last.text.should eq (year + 2).to_s
      last[:href].should eq event_courses_path(year: year + 2, group: top_group.id)
    end
  end


  context "GET index content" do
    let(:slk) { event_kinds(:slk)}
    let(:main) { dom.find("#main") }
    let(:slk_ev) { Fabricate(:course, group: groups(:top_layer), kind: event_kinds(:slk), maximum_participants: 20, state: 'Geplant' ) }
    let(:glk_ev) { Fabricate(:course, group: groups(:top_group), kind: event_kinds(:glk), maximum_participants: 20 ) }

    before do 
      add_date(slk_ev, "2009-01-2", "2010-01-2", "2010-01-02", "2011-01-02") 
      add_date(glk_ev, "2009-01-2", "2011-01-02") 
    end

    it "list courses within table" do
      get :index, year: 2010
      main.find('h2').text.should eq 'Scharleiterkurs'
      main.find('table tr:eq(2) td:eq(1) a').text.should eq 'Eventus'
      main.find('table tr:eq(2) td:eq(1)').text.should eq "EventusSLK  Top"
      main.find('table tr:eq(2) td:eq(1) a')[:href].should eq group_event_path(slk_ev.group, slk_ev)
      main.find('table tr:eq(2) td:eq(2)').native.to_xml.should eq "<td>02.01.2009 <span class=\"muted\"/><br/>02.01.2010 <span class=\"muted\"/><br/>02.01.2010 <span class=\"muted\"/><br/>02.01.2011 <span class=\"muted\"/></td>"
      main.find('table tr:eq(2) td:eq(3)').text.should eq '0 von 20'
      main.find('table tr:eq(2) td:eq(4)').text.should eq 'Geplant'
    end

    it "does not show details for users how cannot manage course" do
      person = Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_one)).person
      sign_in(person)
      get :index, year: 2010
      main.find('table td:eq(1) a').text.should eq 'Scharleiterkurs'
      main.find('table td:eq(1)').text.should eq "ScharleiterkursTop"
      main.find('table td:eq(1) a')[:href].should eq group_event_path(slk_ev.group, slk_ev)
      main.find('table td:eq(2)').native.to_xml.should eq "<td>02.01.2010<br/>02.01.2010</td>"
      expect { main.find('table td:eq(3)') }.to raise_error
    end

    it "groups courses by course type" do
      get :index, year: 2011
      main.all('h2').size.should eq 2
      main.find('tr:eq(1) h2').text.should eq 'Gruppenleiterkurs'
      main.find('tr:eq(3) h2').text.should eq 'Scharleiterkurs'
    end

    it "filters list with group param" do
      get :index, year: 2011, group: glk_ev.group.id
      main.all('h2').size.should eq 1
    end

    it "filters list by year, keeps year in dropdown" do
      get :index, year: 2010
      main.all('h2').size.should eq 1
      dropdown.find('li:eq(3) a')[:href].should eq event_courses_path(year: 2010, group: top_group.id)
    end

    def add_date(event, *dates)
      dates.each { |date| event.dates.build(start_at: Time.zone.parse(date)) } 
      event.save
    end
  end
end


