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

    it "list all groups by default" do
      get :index
      title_text.should eq prefixed('allen Gruppen')
    end

    it "list specific group" do
      get :index, group: top_layer.id
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
      first[:href].should eq event_courses_path(year: Date.today.year)

      middle.text.should eq top_layer.name
      middle[:href].should eq event_courses_path(year: Date.today.year, group: top_layer.id)

      last.text.should eq top_group.name
      last[:href].should eq event_courses_path(year: Date.today.year, group: top_group.id)
    end
  end

  context "GET index, shows yearwise paging" do
    before { get :index }
    let(:tabs) { dom.find('#content .nav') }

    it "tabs contain year based pagination" do
      first, last = tabs.all('a').first, tabs.all('a').last
      first.text.should eq (year - 3).to_s
      first[:href].should eq event_courses_path(year: year - 3)

      last.text.should eq (year + 2).to_s
      last[:href].should eq event_courses_path(year: year + 2)
    end
  end


  context "GET index shows dropdown" do
    let(:slk) { event_kinds(:slk)}
    let(:main) { dom.find("#main") }
    let(:slk_ev) { Fabricate(:course, group: groups(:top_layer), kind: event_kinds(:slk), maximum_participants: 20 ) }
    let(:glk_ev) { Fabricate(:course, group: groups(:top_group), kind: event_kinds(:glk), maximum_participants: 20 ) }

    before do 
      add_date(slk_ev, "2009-01-2", "2010-01-2", "2010-01-02") 
      add_date(glk_ev, "2009-01-2", "2011-01-02") 
    end

    it "list courses within table" do
      get :index, year: 2010
      main.find('h2').text.should eq 'Scharleiterkurs'
      main.find('table td:eq(1)').native.to_xml.should eq '<td>Scharleiterkurs<br/><span class="muted">Top</span></td>'
      main.find('table td:eq(2)').text.should eq 'Scharleiterkurs'
      main.find('table td:eq(3)').text.should eq '0 von 20'
      main.find('table td:eq(4)').native.to_xml.should eq "<td>02.01.2010<br/>02.01.2010</td>"
    end

    it "groups courses by course type" do
      get :index, year: 2009
      main.all('h2').size.should eq 2
      main.find('h2:eq(1)').text.should eq 'Gruppenleiterkurs'
      main.find('h2:eq(2)').text.should eq 'Scharleiterkurs'
    end

    it "filters list with group param" do
      get :index, year: 2009, group: slk_ev.group.id
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


