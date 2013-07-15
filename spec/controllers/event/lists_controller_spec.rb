require 'spec_helper'

describe Event::ListsController do
  before { sign_in(person) }
  let(:person) { people(:bottom_member) }
  
  context "GET #events" do
    it "populates events in group_hierarchy, order by start_at" do
      a = create_event(:bottom_layer_one)
      b = create_event(:top_layer, start_at: 1.year.ago)
      
      get :events
      
      assigns(:events_by_month).values.should eq [[b],[a]]
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
      let(:year_range) { (year-2..year+1) }

      it "defaults to current year" do
        get :courses
        assigns(:year).should eq year
        controller.send(:year_range).should eq year_range
      end

      it "reads year from params, populates vars"do
        get :courses, year: 2010
        assigns(:year).should eq 2010
        controller.send(:year_range).should eq 2008..2011
      end
    end

    context "filter per group" do
      before { sign_in(people(:top_leader)) }

      it "defaults to toplevel group with courses in hiearchy" do
        get :courses
        assigns(:group_id).should eq groups(:top_group).id
      end

      it "can be set via param, only if year is present" do
        get :courses, year: 2010, group_id: groups(:top_layer).id
        assigns(:group_id).should eq groups(:top_layer).id
      end
    end


    context "exports to csv" do
      let(:rows) { response.body.split("\n") }
      let(:course)  { Fabricate(:course) }
      before { Fabricate(:event_date, event: course)  }

      it "renders csv headers" do
        controller.stub(current_user: people(:root))
        get :courses, format: :csv
        response.should be_success
        rows.first.should match(/^Organisatoren;Kursnummer;Kursart;.*Hauptleitung Telefonnummern$/)
        rows.should have(2).rows
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

