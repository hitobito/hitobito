require 'spec_helper'
require_relative '../../support/fabrication.rb'

describe Event::Camp do

  describe ".role_types" do
    subject { Event::Camp.role_types }

    it { should include(Event::Role::Leader) }
    it { should include(Event::Role::AssistantLeader) }
    it { should include(Event::Role::Cook) }
    it { should include(Event::Role::Treasurer) }
    it { should include(Event::Role::Speaker) }
    it { should include(Event::Role::Participant) }
    it { should include(Event::Camp::Role::Coach) }
  end

  context ".kind_class" do
    subject { Event::Camp.kind_class }

    it "is loaded correctly" do
      should == Event::Camp::Kind
      subject.name == 'Event::Camp::Kind'
    end

  end

  context "#coach" do
    let(:person)  { Fabricate(:person) }
    let(:person1) { Fabricate(:person) }

    let(:event)   { Fabricate(:camp, coach_id: person.id).reload }

    subject { event }

    its(:coach) { should == person }
    its(:coach_id) { should == person.id }

    it "shouldn't change the coach if the same is already set" do
      subject.coach_id = person.id
      expect { subject.save! }.not_to change { Event::Role.count }
      subject.coach.should eq person
    end

    it "should update the coach if another person is assigned" do
      event.coach_id = person1.id
      event.save.should be_true
      event.coach.should eq person1
    end

    it "shouldn't try to add coach if id is empty" do
      event = Fabricate(:camp, coach_id: '')
      event.coach.should be nil
    end

    it "removes existing coach if id is set blank" do
      subject.coach_id = person.id
      subject.save!

      subject.coach_id = ''
      expect { subject.save! }.to change { Event::Role.count }.by(-1)
    end

    it "removes existing and creates new coach on reassignment" do
      subject.coach_id = person.id
      subject.save!

      new_coach = Fabricate(:person)
      subject.coach_id = new_coach.id
      expect { subject.save! }.not_to change { Event::Role.count }
      Event.find(subject.id).coach_id.should == new_coach.id
      subject.participations.where(person_id: person.id).should_not be_exists
    end

  end

end
