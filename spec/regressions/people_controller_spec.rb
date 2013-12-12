# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

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


  include_examples 'crud controller', skip: [%w(create), %w(destroy)]

  describe '#show' do
    let(:page_content) { ['Bearbeiten', 'Info', 'Verlauf', 'Aktive Rollen', 'Passwort ändern'] }

    it 'cannot view person in uppper group' do
      sign_in(Fabricate(Group::BottomGroup::Leader.name.to_sym, group: bottom_group).person)
      expect do
        get :show, group_id: top_group.id, id: top_leader.id
      end.to raise_error(CanCan::AccessDenied)
    end

    it 'renders my own page' do
      get :show, group_id: top_group.id, id: top_leader.id
      page_content.each { |text|  response.body.should =~ /#{text}/ }
    end

    it 'renders page of other group member' do
      sign_in(Fabricate(Group::TopGroup::Member.name.to_sym, group: top_group).person)
      get :show, group_id: top_group.id, id: other.id
      page_content.grep(/Info/).each { |text|  response.body.should =~ /#{text}/ }
      page_content.grep(/[^Info]/).each { |text|  response.body.should_not =~ /#{text}/ }
      dom.should_not have_selector('a[data-method="delete"] i.icon-trash')
    end

    it 'leader can see link to remove role' do
      get :show, group_id: top_group.id, id: other.id
      dom.should have_selector('a[data-method="delete"] i.icon-trash')
    end

    it 'leader can see created and updated info' do
      sign_in(top_leader)
      get :show, group_id: top_group.id, id: other.id
      dom.should have_selector('dt', text: 'Erstellt')
      dom.should have_selector('dt', text: 'Geändert')
    end

    it 'member without permission to see details cannot see created or updated info' do
      person1 = (Fabricate(Group::BottomGroup::Member.name.to_sym, group: bottom_group).person)
      person2 = (Fabricate(Group::BottomGroup::Member.name.to_sym, group: bottom_group).person)
      sign_in(person1)
      get :show, id: person2
      dom.should_not have_selector('dt', text: 'Erstellt')
      dom.should_not have_selector('dt', text: 'Geändert')
    end
  end

  describe_action :put, :update, id: true do
    let(:params) { { person: { birthday: '33.33.33' } } }

    it 'displays old value again' do
      should render_template('edit')
      dom.should have_selector('.error input[value="33.33.33"]')
    end
  end

  describe 'role section' do
    let(:params) { { group_id: top_group.id, id: top_leader.id } }
    let(:section) { dom.all('aside section')[0] }

    it 'contains roles' do
      get :show, params
      section.find('h2').text.should eq 'Aktive Rollen'
      section.find('tr:eq(1)').text.should include('TopGroup')
      section.should have_css('.btn-small.dropdown-toggle')
      section.find('tr:eq(1) table tr:eq(1)').text.should include('Leader')
      edit_role_path = edit_group_role_path(top_group, top_leader.roles.first)
      section.find('tr:eq(1) table tr:eq(1) td:eq(2)').native.to_xml.should include edit_role_path
    end
  end

  describe 'event sections' do
    let(:params) { { group_id: top_group.id, id: top_leader.id } }
    let(:header) { section.find('h2').text }
    let(:dates) { section.find('tr:eq(1) td:eq(2)').text.strip }
    let(:label) { section.find('tr:eq(1) td:eq(1)') }
    let(:label_link) { label.find('a') }
    let(:course) { Fabricate(:course, groups: [groups(:top_layer)], kind: event_kinds(:slk))  }

    context 'pending applications' do
      let(:section) { dom.all('aside section')[1] }
      let(:date) { Time.zone.parse('02-01-2010') }

      it 'is missing if we have no applications' do
        get :show, params
        dom.should have_css('aside section', count: 2) # only role and qualification
      end

      it 'lists application' do
        appl = create_application(date)
        get :show, params
        header.should eq 'Anmeldungen'
        label_link[:href].should eq "/groups/#{course.group_ids.first}/events/#{course.id}/participations/#{appl.participation.id}"
        label_link.text.should =~ /Eventus/
        label.text.should =~ /Top/
        dates.should eq '02.01.2010 - 07.01.2010'
      end
    end

    context 'upcoming events' do
      let(:section) { dom.all('aside section')[1] }
      let(:date) { 2.days.from_now }
      let(:pretty_date) { date.strftime('%d.%m.%Y %H:%M') + ' - ' + (date + 5.days).strftime('%d.%m.%Y %H:%M') }

      it 'is missing if we have no events' do
        get :show, params
        dom.should have_css('aside section', count: 2) # only role and qualification
      end

      it 'is missing if we have no upcoming events' do
        create_participation(10.days.ago, true)
        get :show, params
        dom.should have_css('aside section', count: 2) # only role and qualification
      end

      it 'lists event label, link and dates' do
        create_participation(date, true)
        get :show, params
        header.should eq 'Anlässe'
        label_link[:href].should eq group_event_path(course.groups.first, course)
        label_link.text.should eq 'Eventus'
        label.text.should =~ /Top/
        dates.should eq pretty_date
      end
    end

    def create_application(date)
      Fabricate(:event_application, priority_1: course, participation: create_participation(date, false))
    end

    def create_participation(date, active_participation = false)
      set_start_finish(course, date, date + 5.days)
      Fabricate(:event_participation, person: top_leader, event: course, active: active_participation)
    end

  end

  describe '#history' do
    let(:params) { { group_id: top_group.id, id: other.id } }
    it 'list current role and group' do
      get :history, params
      dom.all('table tbody tr').size.should eq 1
      role_row = dom.find('table tbody tr:eq(1)')
      role_row.find('td:eq(1) a').text.should eq 'TopGroup'
      role_row.find('td:eq(2)').text.strip.should eq 'Member'
      role_row.find('td:eq(3)').text.should be_present
      role_row.find('td:eq(4)').text.should_not be_present
    end

    it 'lists past roles' do
      role = Fabricate(Group::BottomGroup::Member.name.to_sym, group: bottom_group, person: other)
      role.created_at = Time.zone.now - 2.years
      role.destroy
      get :history, params
      dom.all('table tbody tr').size.should eq 2
      role_row = dom.find('table tbody tr:eq(1)')
      role_row.find('td:eq(1) a').text.should eq 'Group 11'
      role_row.find('td:eq(2)').text.strip.should eq 'Member'
      role_row.find('td:eq(3)').text.should be_present
      role_row.find('td:eq(4)').text.should be_present
    end

    it 'lists roles in other groups' do
      Fabricate(Group::TopGroup::Member.name.to_sym, group: top_group, person: other)
      get :history, params
      dom.all('table tbody tr').size.should eq 2
      role_row = dom.find('table tbody tr:eq(2)')
      role_row.find('td:eq(1) a').text.should eq 'TopGroup'
      role_row.find('td:eq(4)').text.should_not be_present
    end

    it 'lists past roles in other groups' do
      role = Fabricate(Group::TopGroup::Member.name.to_sym, group: top_group, person: other)
      role.created_at = Time.zone.now - 2.years
      role.destroy
      get :history, params
      dom.all('table tbody tr').size.should eq 2
      role_row = dom.find('table tbody tr:eq(2)')
      role_row.find('td:eq(1) a').text.should eq 'TopGroup'
      role_row.find('td:eq(4)').text.should be_present
    end

    it "lists person's events" do
      course1 = Fabricate(:course, groups: [groups(:top_layer)], kind: event_kinds(:slk))
      event1 = Fabricate(:event, groups: [groups(:top_layer)])
      event2 = Fabricate(:event, groups: [groups(:top_layer)])
      [course1, event1, event2].each do |event|
        Fabricate(:event_role, participation: Fabricate(:event_participation, person: people(:top_leader), event: event), type: 'Event::Role::Leader')
      end

      get :history, group_id: top_group.id, id: top_leader.id

      events = dom.find('events')

      events.should have_selector('h2', text: 'Kurse')
      events.should have_selector('h2', text: 'Anlässe')

      events.all('tr td a').size.should eq 3
    end

  end


  describe 'redirect_url' do
    it 'should adjust url if param redirect_url is given' do
      get :new, group_id: top_group.id,
                role: { type: 'Group::TopGroup::Member', group_id: top_group.id },
                return_url: 'foo'

      dom.all('a', text: 'Abbrechen').first[:href].should eq 'foo'
      dom.find('input#return_url').value.should eq 'foo'

    end

  end

end
