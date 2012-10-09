require 'spec_helper'

describe Event::Course do
  
  subject do
    event = Fabricate(:course, group: groups(:be) )
    Fabricate(Event::Role::Leader.name.to_sym, participation: Fabricate(:event_participation, event: event))
    Fabricate(Event::Role::AssistantLeader.name.to_sym, participation: Fabricate(:event_participation, event: event))
    Fabricate(Event::Course::Role::Participant.name.to_sym, participation: Fabricate(:event_participation, event: event))
    Fabricate(Event::Course::Role::Participant.name.to_sym, participation: Fabricate(:event_participation, event: event))
    event.reload
  end
  
  context "#application_possible?" do
    before { subject.state = 'application_open' }
    
    context "without opening date" do
      it { should be_application_possible }
    end
    
    context "with opening date in the past" do
      before { subject.application_opening_at = Date.today - 1 }
      it { should be_application_possible }
      
      context "in other state" do
        before { subject.state = 'application_closed' }
        it { should_not be_application_possible }
      end
    end

    context "with ng date today" do
      before { subject.application_opening_at = Date.today}
      it { should be_application_possible }
    end
    
    context "with opening date in the future" do
      before { subject.application_opening_at = Date.today + 1}
      it { should_not be_application_possible }
    end
    
    context "with closing date in the past" do
      before { subject.application_closing_at = Date.today - 1}
      it { should be_application_possible } # yep, we do not care about the closing date
    end
    
    context "in other state" do
      before { subject.state = 'created' }
      it { should_not be_application_possible }
    end

  end

  context "#advisor" do
    let(:person) { Fabricate(:person) }
    let(:person1) { Fabricate(:person) }

    it "should add advisor if none is defined yet" do
      event = Fabricate(:course, advisor_id: person.id)
      event.advisor.should eq person
    end

    it "shouldn't change the advisor if the same is already set" do
      event = Fabricate(:course, advisor_id: person.id)
      event.advisor_id = person.id
      event.save.should be_true
      event.advisor.should eq person
    end

    it "should update the advisor if another person is assigned" do
      event = Fabricate(:course, advisor_id: person.id)
      event.advisor_id = person1.id
      event.save.should be_true
      event.advisor.should eq person1
    end


  end
  
end
