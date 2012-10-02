require 'spec_helper'

describe Event do
  
  subject do
    event = Fabricate(:event, group: groups(:top_group) )
    Fabricate(Event::Participation::Leader.name.to_sym, event: event)
    Fabricate(Event::Participation::Participant.name.to_sym, event: event)
    p = Fabricate(:person)
    Fabricate(Event::Participation::Participant.name.to_sym, event: event, person: p)
    Fabricate(Event::Participation::Participant.name.to_sym, event: event, label: 'Irgendwas', person: p)
    event
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
  
  context ".in_year" do
    let(:group) { groups(:top_layer) }
    let(:event) { Fabricate(:event, group: group) }
    before { add_date "2000-01-01" }

    it "uses dates create_at to determine if event matches" do
      Event.in_year(2001).should_not be_present
      Event.in_year(2000).first.should eq event 
      Event.in_year("2000").first.should eq event
      Event.in_year(2000).size.should eq 1
    end

    it "raises argument error"do
      expect { Event.in_year('')}.to raise_error(ArgumentError)
      expect { Event.in_year(-1)}.to raise_error(ArgumentError)
      expect { Event.in_year('asdf')}.to raise_error(ArgumentError)
    end

    def add_date(start_at)
      start_at = DateTime.parse(start_at)
      event.dates.build({start_at: start_at})
      event.save
    end

  end
end
