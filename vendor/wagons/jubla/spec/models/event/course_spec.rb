require 'spec_helper'

describe Event::Course do
  
  subject do
    event = Fabricate(:course, groups: [groups(:be)] )
    Fabricate(Event::Role::Leader.name.to_sym, participation: Fabricate(:event_participation, event: event))
    Fabricate(Event::Role::AssistantLeader.name.to_sym, participation: Fabricate(:event_participation, event: event))
    Fabricate(Event::Course::Role::Participant.name.to_sym, participation: Fabricate(:event_participation, event: event))
    Fabricate(Event::Course::Role::Participant.name.to_sym, participation: Fabricate(:event_participation, event: event))
    event.reload
  end
    
  describe ".role_types" do
    subject { Event::Course.role_types }
    
    it { should include(Event::Course::Role::Participant) }
    it { should include(Event::Course::Role::Advisor) }
    it { should_not include(Event::Role::Participant) }
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
    let(:person)  { Fabricate(:person) }
    let(:person1) { Fabricate(:person) }
    
    let(:event)   { Fabricate(:course, advisor_id: person.id).reload } 
    
    subject { event }
     
    its(:advisor) { should == person }
    its(:advisor_id) { should == person.id }
    
    it "shouldn't change the advisor if the same is already set" do
      subject.advisor_id = person.id
      expect { subject.save! }.not_to change { Event::Role.count }
      subject.advisor.should eq person
    end

    it "should update the advisor if another person is assigned" do
      event.advisor_id = person1.id
      event.save.should be_true
      event.advisor.should eq person1
    end

    it "shouldn't try to add advisor if id is empty" do
      event = Fabricate(:course, advisor_id: '')
      event.advisor.should be nil
    end
    
    it "removes existing advisor if id is set blank" do
      subject.advisor_id = person.id
      subject.save!
      
      subject.advisor_id = ''
      expect { subject.save! }.to change { Event::Role.count }.by(-1) 
    end
    
    it "removes existing advisor participation if id is set blank" do
      subject.advisor_id = person.id
      subject.save!
      
      subject.advisor_id = ''
      expect { subject.save! }.to change { Event::Participation.count }.by(-1) 
    end
    
    it "removes existing and creates new advisor on reassignment" do
      subject.advisor_id = person.id
      subject.save!
      
      new_advisor = Fabricate(:person)
      subject.advisor_id = new_advisor.id
      expect { subject.save! }.not_to change { Event::Role.count }
      Event.find(subject.id).advisor_id.should == new_advisor.id
      subject.participations.where(person_id: person.id).should_not be_exists
    end
    
  end

  
end
