# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe EventsController, type: :controller do

  # always use fixtures with crud controller examples, otherwise request reuse might produce errors
  let(:test_entry) { ev = events(:top_course); ev.dates.clear; ev }
  let(:group) { test_entry.groups.first }
  let(:date)  { { label: 'foo', start_at_date: Date.today, finish_at_date: Date.today } }
  let(:test_entry_attrs) do
    { name: 'Chief Leader Course',
      group_ids: [group.id],
      dates_attributes: [date] }
  end

  def scope_params
    { group_id: group.id }
  end

  before { sign_in(people(:top_leader)) }

  def self.it_should_redirect_to_index
    it { should redirect_to course_group_events_path(group.id, returning: true) }
  end

  include_examples 'crud controller', skip: [%w(index), %w(new)]

  def deep_attributes(*args)
    { name: 'Chief Leader Course', dates_attributes: [date], group_ids: [group.id] }
  end


  describe 'GET #index' do
    context '.html' do
      render_views
      let(:group) { groups(:top_layer) }
      let(:dom) { Capybara::Node::Simple.new(response.body) }
      let(:today) { Date.today }
      let(:last_year) { 1.year.ago }

      it 'renders button to add new events' do
        get :index, group_id: group.id, year: 2012
        dom.all('.btn-toolbar .btn')[0].text.should include 'Anlass erstellen'
      end

      it 'renders button to add new courses' do
        get :index, group_id: group.id, type: 'Event::Course', year: 2012
        dom.all('.btn-toolbar .btn')[0].text.should include 'Kurs erstellen'
      end

      it 'renders button to export courses' do
        get :index, group_id: group.id, type: 'Event::Course', year: 2012
        dom.all('.btn-toolbar .btn')[1].text.should include 'CSV Export'
      end

      it 'lists entries for current year' do
        ev = event_with_date(start_at: today)
        event_with_date(start_at: last_year)
        get :index, group_id: group.id
        dom.all('#main table tbody tr').count.should eq 1
        dom.find('#main table tbody tr').text.should include ev.name
        dom.find_link(today.year.to_s).native.parent[:class].should eq 'active'
      end

      it 'pages per year' do
        event_with_date(start_at: today)
        ev = event_with_date(start_at: last_year)
        get :index, group_id: group.id, year: last_year.year
        dom.all('.pagination li').count.should eq 6
        dom.all('#main table tbody tr').count.should eq 1
        dom.find('#main table tbody tr').text.should include ev.name
        dom.find_link(last_year.year.to_s).native.parent[:class].should eq 'active'
      end

      def event_with_date(opts = {})
        opts = { groups: [group], state: 'application_open', start_at: Date.today }.merge(opts)
        event = Fabricate(:event, groups: opts[:groups], state: opts[:state])
        set_start_dates(event, opts[:start_at])
        event
      end
    end

    context '.csv' do

      let(:group) { groups(:top_layer) }

      it 'renders events csv' do
        get :index, group_id: group.id, format: :csv, year: 2012
        response.body.lines.should have(2).items
      end

      it 'renders courses csv' do
        get :index, group_id: group.id, format: :csv, year: 2012, type: Event::Course.sti_name
        response.body.lines.should have(2).items
      end

    end

  end

  describe 'GET #new' do
    render_views
    let(:group) { groups(:top_group) }
    let(:dom) { Capybara::Node::Simple.new(response.body) }

    it 'renders new form' do
      get :new, group_id: group.id, event: { type: 'Event::Course' }
      dom.find('input#event_type')[:type].should eq 'hidden'
      dom.all('#questions_fields .fields').count.should eq 3
      dom.all('#dates_fields').count.should eq 1
    end
  end

end
