# encoding:  utf-8

require 'spec_helper'

describe PeopleController, type: :controller do

  let(:top_leader) { people(:top_leader) }
  let(:top_group) { groups(:top_group) }
  let(:bottom_group) { groups(:bottom_group_one_one) }
  let(:test_entry) { top_leader }
  let(:test_entry_attrs) { { first_name: 'foo', last_name: 'bar' } }
  let(:other) { Fabricate(Group::TopGroup::Member.name.to_sym, group: top_group).person  }
  let(:dom) { Capybara::Node::Simple.new(response.body) }

  before { sign_in(top_leader) } 


  def scope_params
    return { group_id: top_group.id } unless example.metadata[:action] == :new
    {  group_id: top_group.id, role: { type: 'Group::TopGroup::Member', group_id: top_group.id }  }
  end


  include_examples 'crud controller', skip: [ %w(create), %w(destroy)]

  describe "#show" do
    let(:page_content) { ['Bearbeiten','Info','Verlauf','Aktive Rollen','Passwort ändern'] }

    it "cannot view person in uppper group" do
      sign_in(Fabricate(Group::BottomGroup::Leader.name.to_sym, group: bottom_group).person)
      get :show, group_id: top_group.id, id: top_leader.id
      flash[:alert].should eq "Sie sind nicht berechtigt, diese Seite anzuzeigen"
    end

    it "renders my own page" do
      get :show, group_id: top_group.id, id: top_leader.id
      page_content.each { |text|  response.body.should =~ /#{text}/ } 
    end

    it "renders page of other group member" do
      sign_in(Fabricate(Group::TopGroup::Member.name.to_sym, group: top_group).person)
      get :show, group_id: top_group.id, id: other.id
      page_content.grep(/Info/).each { |text|  response.body.should =~ /#{text}/ } 
      page_content.grep(/[^Info]/).each { |text|  response.body.should_not =~ /#{text}/ } 
      dom.should_not have_selector('a[data-method="delete"] i.icon-trash')
    end

    it "leader can see link to remove role" do
      get :show, group_id: top_group.id, id: other.id
      dom.should have_selector('a[data-method="delete"] i.icon-trash')
    end

  end

  describe "#show applications aside" do
    let(:params) { { group_id: top_group.id, id: top_leader.id } }
    let(:label) { aside.find('tr:eq(1) td:eq(1) a').native.to_xml }
    let(:dates) { aside.find('tr:eq(1) td:eq(2)').text.strip }
    let(:course) { Fabricate(:course, group: groups(:top_layer), kind: event_kinds(:slk))  } 

    context "pending event applications" do
      let(:aside) { dom.find('aside[data-role="applications"]') }
      let(:date) { Time.zone.parse("02-01-2010") }
      let(:text) { "<a href=\"/events/1/applications/1\">Scharleiterkurs<br/><span class=\"muted\">Top</span></a>" }

      it "renders only if we have applications" do
        get :show, params 
        expect { aside }.to raise_error Capybara::ElementNotFound
      end

      it "lists open applications" do
        create_application(date)
        get :show, params 
        aside.find('h2').text.should eq 'Anmeldungen'
        label.should eq text
        dates.should eq '02.01.2010'
      end
    end

    context "upcoming events" do
      let(:aside) { dom.find('aside[data-role="upcoming"]') }
      let(:label) { aside.find('tr:eq(1) td:eq(1)').native.to_xml }
      let(:date) { 2.days.from_now }
      let(:pretty_date) { date.strftime("%d.%m.%Y")}

      it "renders only if we have applications" do
        get :show, params 
        expect { aside }.to raise_error Capybara::ElementNotFound
      end

      it "lists upcoming events" do
        create_participation(date)
        get :show, params 
        aside.find('h2').text.should eq 'Events'
        label.should eq "<td>Scharleiterkurs<br/><span class=\"muted\">Top</span>\n</td>"
        dates.should eq pretty_date
      end
    end
    

    def create_application(date)
      set_event_date(date)
      participation = Fabricate("Event::Participation::Leader", person: top_leader) 
      Fabricate(:event_application, priority_1: course, participation: participation)
    end

    def create_participation(date)
      set_event_date(date)
      participation = Fabricate("Event::Participation::Leader", person: top_leader, event: course) 
    end

    def set_event_date(date)
      course.dates.build(start_at: date)
      course.save
    end
  end

  describe "#history" do
    let(:params) { {group_id: top_group.id, id: other.id } }
    it "list current role and group" do
      get :history, params
      dom.all('table tbody tr').size.should eq 1 
      role_row = dom.find('table tbody tr:eq(1)')
      role_row.find('td:eq(1) a').text.should eq 'TopGroup'
      role_row.find('td:eq(2)').text.strip.should eq 'Rolle'
      role_row.find('td:eq(3)').text.should be_present
      role_row.find('td:eq(4)').text.should_not be_present
    end

    it "lists past roles" do
      Fabricate(Group::BottomGroup::Member.name.to_sym, group: bottom_group, person: other).destroy
      get :history, params
      dom.all('table tbody tr').size.should eq 2 
      role_row = dom.find('table tbody tr:eq(2)')
      role_row.find('td:eq(1) a').text.should eq 'Group 11'
      role_row.find('td:eq(2)').text.strip.should eq 'Rolle'
      role_row.find('td:eq(3)').text.should be_present
      role_row.find('td:eq(4)').text.should be_present
    end

    it "lists roles in other groups" do
      Fabricate(Group::TopGroup::Member.name.to_sym, group: top_group, person: other)
      get :history, params
      dom.all('table tbody tr').size.should eq 2 
      role_row = dom.find('table tbody tr:eq(2)')
      role_row.find('td:eq(1) a').text.should eq 'TopGroup'
      role_row.find('td:eq(4)').text.should_not be_present
    end

    it "lists past roles in other groups" do
      Fabricate(Group::TopGroup::Member.name.to_sym, group: top_group, person: other).destroy
      get :history, params
      dom.all('table tbody tr').size.should eq 2 
      role_row = dom.find('table tbody tr:eq(2)')
      role_row.find('td:eq(1) a').text.should eq 'TopGroup'
      role_row.find('td:eq(4)').text.should be_present
    end

  end

end
