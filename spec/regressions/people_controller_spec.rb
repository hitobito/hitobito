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
  describe "role aside" do
    let(:params) { { group_id: top_group.id, id: top_leader.id } }
    let(:aside) { dom.find('aside[data-role="roles"]') }
    it "is missing if we have no applications" do
      get :show, params 
      aside.find('header').text.should eq 'Aktive Rollen'
      aside.find('tr:eq(1) td:eq(1)').text.should include("Rolle")
      aside.find('tr:eq(1) td:eq(1)').text.should include("TopGroup")
      edit_role_path = edit_group_role_path(top_group, top_leader.roles.first)
      aside.find('tr:eq(1) td:eq(2)').native.to_xml.should include edit_role_path
    end
  end

  describe "event asides" do
    let(:params) { { group_id: top_group.id, id: top_leader.id } }
    let(:header) { aside.find('header').text }
    let(:dates) { aside.find('tr:eq(1) td:eq(2)').text.strip }
    let(:label) { aside.find('tr:eq(1) td:eq(1)') }
    let(:label_link) { label.find('a') }
    let(:course) { Fabricate(:course, group: groups(:top_layer), kind: event_kinds(:slk))  } 

    context "pending applications" do
      let(:aside) { dom.find('aside[data-role="applications"]') }
      let(:date) { Time.zone.parse("02-01-2010") }

      it "is missing if we have no applications" do
        get :show, params 
        expect { aside }.to raise_error Capybara::ElementNotFound
      end

      it "lists application" do
        create_application(date)
        get :show, params 
        header.should eq 'Anmeldungen'
        label_link[:href].should eq "/events/1/participations/1"
        label_link.text.should =~ /Scharleiterkurs/
        label.text.should =~ /Top/
        dates.should eq '02.01.2010'
      end
    end

    context "upcoming events" do
      let(:aside) { dom.find('aside[data-role="upcoming"]') }
      let(:date) { 2.days.from_now }
      let(:pretty_date) { date.strftime("%d.%m.%Y")}

      it "is missing if we have no events" do
        get :show, params 
        expect { aside }.to raise_error Capybara::ElementNotFound
      end

      it "is missing if we have no upcoming events" do
        create_participation(2.days.ago,true)
        get :show, params 
        expect { aside }.to raise_error Capybara::ElementNotFound
      end

      it "lists event label, link and dates" do
        create_participation(date,true)
        get :show, params 
        header.should eq 'Events'
        label_link[:href].should eq group_event_path(course.group, course)
        label_link.text.should eq "Eventus"
        label.text.should =~ /Top/
        dates.should eq pretty_date
      end
    end

    def create_application(date)
      Fabricate(:event_application, priority_1: course, participation: create_participation(date,false))
    end
      
    def create_participation(date,active_participation=false)
      set_event_date(date)
      Fabricate(:event_participation, person: top_leader, event: course, active: active_participation) 
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
