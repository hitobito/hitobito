# == Schema Information
#
# Table name: events
#
#  id                     :integer          not null, primary key
#  group_id               :integer          not null
#  type                   :string(255)
#  name                   :string(255)      not null
#  number                 :string(255)
#  motto                  :string(255)
#  cost                   :string(255)
#  maximum_participants   :integer
#  contact_id             :integer
#  description            :text
#  location               :text
#  application_opening_at :date
#  application_closing_at :date
#  application_conditions :text
#  kind_id                :integer
#  state                  :string(60)
#  priorization           :boolean          default(FALSE), not null
#  requires_approval      :boolean          default(FALSE), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  participant_count      :integer          default(0)
#

require 'spec_helper'

describe Event do
  
  subject do
    event = Fabricate(:event, group: groups(:top_group) )
    Fabricate(Event::Role::Leader.name.to_sym, participation:  Fabricate(:event_participation, event: event))
    Fabricate(Event::Role::Participant.name.to_sym, participation:  Fabricate(:event_participation, event: event))
    p = Fabricate(:event_participation, event: event)
    Fabricate(Event::Role::Participant.name.to_sym, participation: p)
    Fabricate(Event::Role::Participant.name.to_sym, participation: p, label: 'Irgendwas')
    event.reload
  end
  
  
  its(:participant_count) { should == 2 }
  
  context "#application_possible?" do
    
    context "without opening and closing dates" do
      it "is open without maximum participant" do
        should be_application_possible
      end
      
      it "is closed when maximum participants is reached" do
        subject.maximum_participants = 20
        subject.participant_count = 20
        should_not be_application_possible
      end
      
      it "is open when maximum participants is not yet reached" do
        subject.maximum_participants = 20
        subject.participant_count = 19
        should be_application_possible
      end
    end
    
    context "with closing date in the future" do
      before { subject.application_closing_at = Date.today + 1 }
      
       it "is open without maximum participant" do
        should be_application_possible
      end
      
      it "is closed when maximum participants is reached" do
        subject.maximum_participants = 20
        subject.participant_count = 20
        should_not be_application_possible
      end
      
    end
    
    context "with closing date today" do
      before { subject.application_closing_at = Date.today }
      
      it "is open without maximum participant" do
        should be_application_possible
      end
      
      it "is closed when maximum participants is reached" do
        subject.maximum_participants = 20
        subject.participant_count = 20
        should_not be_application_possible
      end
    end
    
    context "with closing date in the past" do
      before { subject.application_closing_at = Date.today - 1 }
      
      it "is closed without maximum participant" do
        should_not be_application_possible
      end
      
      it "is closed when maximum participants is reached" do
        subject.maximum_participants = 20
        subject.participant_count = 20
        should_not be_application_possible
      end
    end
    
    
    context "with opening date in the past" do
      before { subject.application_opening_at = Date.today - 1 }
      
      it "is open without maximum participant" do
        should be_application_possible
      end
      
      it "is closed when maximum participants is reached" do
        subject.maximum_participants = 20
        subject.participant_count = 20
        should_not be_application_possible
      end
    end
    
    context "with opening date today" do
      before { subject.application_opening_at = Date.today }
      
      it "is open without maximum participant" do
        should be_application_possible
      end
      
      it "is closed when maximum participants is reached" do
        subject.maximum_participants = 20
        subject.participant_count = 20
        should_not be_application_possible
      end
    end
    
    context "with opening date in the future" do
      before { subject.application_opening_at = Date.today + 1 }
      
      it "is closed without maximum participant" do
        should_not be_application_possible
      end
    end
    
    context "with opening and closing dates" do
      before do
        subject.application_opening_at = Date.today - 2
        subject.application_closing_at = Date.today + 2
      end
      
      it "is open" do
        should be_application_possible
      end
      
      it "is closed when maximum participants is reached" do
        subject.maximum_participants = 20
        subject.participant_count = 20
        should_not be_application_possible
      end
      
      it "is open when maximum participants is not yet reached" do
        subject.maximum_participants = 20
        subject.participant_count = 19
        should be_application_possible
      end
    end
    
    context "with opening and closing dates in the future" do
      before do
        subject.application_opening_at = Date.today + 1
        subject.application_closing_at = Date.today + 2
      end
      
      it "is closed" do
        should_not be_application_possible
      end
    end
    
    context "with opening and closing dates in the past" do
      before do
        subject.application_opening_at = Date.today - 2
        subject.application_closing_at = Date.today - 1
      end
      
      it "is closed" do
        should_not be_application_possible
      end
    end
  end
 
  context "finders" do

    let(:top_layer) { groups(:top_layer) }
    let(:slk) { event_kinds(:slk)}
    let(:event) { Fabricate(:event, group: top_layer, kind: slk) }

    context ".in_year" do
      context "one date" do
        before { add_date(event, "2000-01-02") }
    
        it "uses dates create_at to determine if event matches" do
          Event.in_year(2000).size.should eq 1
          Event.in_year(2001).should_not be_present
          Event.in_year(2000).first.should eq event 
          Event.in_year("2000").first.should eq event
        end
        
      end
      
      context "starting at last day of year and another date in the following year" do
        before { add_date(event, "2010-12-31 17:00") }
        before { add_date(event, "2011-01-20") }
    
        it "finds event in old year" do
          Event.in_year(2010).should == [event]
        end
        
        it "finds event in following year" do
          Event.in_year(2011).should == [event]
        end
        
        it "does not find event in past year" do
          Event.in_year(2009).should be_blank
        end
      end
    end

    context ".upcoming" do
      subject { Event.upcoming }
      it "does not find past events" do
        add_date(event, "2010-12-31 17:00")
        should_not be_present
      end

      it "does find upcoming event" do
        event.dates.create(start_at: 2.days.from_now, finish_at: 5.days.from_now)
        should eq [event]
      end
      
      it "does find running event" do
        event.dates.create(start_at: 2.days.ago, finish_at: Time.zone.now)
        should eq [event]
      end
      
      it "does find event ending at 5 to 12" do
        event.dates.create(start_at: 2.days.ago, finish_at: Time.zone.now.midnight + 23.hours + 55.minutes)
        should eq [event]
      end
      
      it "does not find event ending at 5 past 12" do
        event.dates.create(start_at: 2.days.ago, finish_at: Time.zone.now.midnight - 5.minutes)
        should be_blank
      end
      
    end

    def add_date(event,start_at)
      start_at = Time.zone.parse(start_at)
      event.dates.create(start_at: start_at, finish_at: start_at + 5.days)
    end
  end
end
