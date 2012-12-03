require 'spec_helper'

describe Event::ListsController do
  before { sign_in(person) }
  let(:person) { people(:bottom_member) } 
  
  context "GET #events" do
    it "populates events in group_hierarchy, order by finished_at" do
      a = create_event(:bottom_layer_one)
      b = create_event(:top_layer, finish_at: 30.minutes.from_now)
      
      get :events
      
      assigns(:events_by_month).values.should eq [[b,a]]
    end

    it "does not include courses" do
      create_event(:top_layer, type: :course)
      
      get :events
      
      assigns(:events_by_month).should be_empty
    end
    
    it "groups by month" do
      create_event(:top_layer, start_at: Time.zone.parse("2012-10-30"))
      create_event(:top_layer, start_at: Time.zone.parse("2012-11-1"))
      
      get :events
      
      assigns(:events_by_month).keys.should == ['Oktober 2012', 'November 2012']
    end
  end

  context "GET #courses" do
    context "filters by year" do
      let(:year) { Date.today.year }
      let(:year_range) { (year-3..year+1) }

      it "defaults to current year" do
        get :courses
        assigns(:year).should eq year
        assigns(:year_range).should eq year_range
      end

      it "reads year from params, populates vars"do
        get :courses, year: 2010
        assigns(:year).should eq 2010
        assigns(:year_range).should eq year_range
      end

      it "years has a reasonable limit" do
        get :courses, year: 1995
        assigns(:year).should eq year
        assigns(:year_range).should eq year_range
      end
    end

    context "filter per group" do
      before { sign_in(people(:top_leader)) }

      it "defaults to toplevel group with courses in hiearchy" do
        get :courses
        assigns(:group_id).should eq groups(:top_group).id
      end

      it "can be set via param, only if year is present" do
        get :courses, year: 2010, group: groups(:top_layer).id
        assigns(:group_id).should eq groups(:top_layer).id
      end
    end

  end
  
  def create_event(group, hash={})
    hash = {start_at: 4.days.ago, finish_at: 1.day.from_now, type: :event}.merge(hash)
    event = Fabricate(hash[:type], groups: [groups(group)])
    event.dates.create(start_at: hash[:start_at], finish_at: hash[:finish_at])
    event
  end
  
end

