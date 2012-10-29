# encoding: UTF-8
require 'spec_helper'

describe EventsController, type: :controller do
  
  # always use fixtures with crud controller examples, otherwise request reuse might produce errors
  let(:test_entry) { events(:top_course) }
  let(:test_entry_attrs) { { name: 'Chief Leader Course' } }

  before { sign_in(people(:top_leader)) } 

  include_examples 'crud controller', skip: [%w(index), %w(new), %w(create), %w(edit), %w(update), %w(destroy)]

  describe "GET #index" do
    render_views
    let(:group) { groups(:top_group) }
    let(:dom) { Capybara::Node::Simple.new(response.body) } 
    let(:today) { Date.today }
    let(:last_year) { 1.year.ago }

    it "renders dropdown to add new events" do
      get :index, group_id: group.id
      dom.find('.dropdown-toggle').text.should include 'Event hinzufügen'
      [Event, Event::Course].each_with_index do |item, index|
        path = new_group_event_path(event: {group_id: group.id, type: item.sti_name})
        dom.all('.dropdown-menu a')[index].text.should eq item.model_name.human
        dom.all('.dropdown-menu a')[index][:href].should eq path
      end
    end

    it "lists entries for current year" do
      ev = event_with_date(start_at: today)
      event_with_date(start_at: last_year)
      get :index, group_id: group.id
      dom.all('#main table tr').count.should eq 1
      dom.find('#main table tr').text.should include ev.name
      dom.find_link(today.year.to_s).native.parent[:class].should eq 'active'
    end

    it "pages per year" do
      event_with_date(start_at: today)
      ev = event_with_date(start_at: last_year)
      get :index, group_id: group.id, year: last_year.year
      dom.all('.pagination li').count.should eq 5
      dom.all('#main table tr').count.should eq 1
      dom.find('#main table tr').text.should include ev.name
      dom.find_link(last_year.year.to_s).native.parent[:class].should eq 'active'
    end

    def event_with_date(opts = {})
      opts = {group: group, state: 'application_open', start_at: Date.today}.merge(opts)
      event = Fabricate(:event, group: opts[:group], state: opts[:state])
      event.dates.create(label: 'dummy', start_at: opts[:start_at])
      event
    end
  end


end
