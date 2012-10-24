# == Schema Information
#
# Table name: event_participations
#
#  id                     :integer          not null, primary key
#  event_id               :integer          not null
#  person_id              :integer          not null
#  additional_information :text
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  active                 :boolean          default(FALSE), not null
#  application_id         :integer
#

require 'spec_helper'

describe Event::Participation do 
  
  
  let(:course) do
    course = Fabricate(:course, group: groups(:top_layer))
    course.questions << Fabricate(:event_question, event: course)
    course.questions << Fabricate(:event_question, event: course)
    course
  end
  
  

  context "#init_answers" do
    subject { course.participations.new }
    
    context do
      before { subject.init_answers }
      
      it "creates answers from event" do
        subject.answers.collect(&:question).to_set.should == course.questions.to_set
      end
    end
    
    it "does not save associations in database" do
      expect { subject.init_answers }.not_to change { Event::Answer.count }
      expect { subject.init_answers }.not_to change { Event::Participation.count }
    end
  end
  
  context "mass assignments" do
    subject { course.participations.new }
    
    it "assigns application and answers for new record" do
      q = course.questions
      subject.person_id = 42
      subject.attributes = {
            additional_information: 'bla',
            application_attributes: { priority_2_id: 42 }, 
            answers_attributes: [{question_id: q[0].id, answer: 'ja'},
                                  {question_id: q[1].id, answer: 'nein'}]}
      
      subject.additional_information.should == 'bla'
      subject.answers.should have(2).items
    end
    
    it "assigns participation and answers for persisted record" do
      p = Person.first
      subject.person = p
      subject.save!
      
      q = course.questions
      subject.attributes = {
            additional_information: 'bla',
            application_attributes: { priority_2_id: 42 }, 
            answers_attributes: [{question_id: q[0].id, answer: 'ja'},
                                  {question_id: q[1].id, answer: 'nein'}]}
      
      subject.person_id.should == p.id
      subject.additional_information.should == 'bla'
      subject.answers.should have(2).items
    end
  end
  
  describe "#create_participant_role" do
    subject { Fabricate(:event_participation, event: course, application: Fabricate(:event_application)) }
    
    before do
      p = subject
      p.init_answers
      p.save!
    end
        
    it "creates role for given application" do
      expect { subject.create_participant_role(course) }.to change { Event::Course::Role::Participant.count }.by(1)
    end
    
    it "updates answers for other event" do
      quest = course.questions.first
      other = Fabricate(:course, group: groups(:top_layer))
      other.questions << Fabricate(:event_question, event: other)
      other.questions << Fabricate(:event_question, event: other, question: quest.question, choices: quest.choices)

      expect { subject.create_participant_role(other) }.to change { Event::Answer.count }.by(1)
      
      subject.event_id.should == other.id
    end
    
    it "raises error on existing participation" do
      quest = course.questions.first
      other = Fabricate(:course, group: groups(:top_layer))
      Fabricate(:event_participation, event: other, person: subject.person, application: Fabricate(:event_application))

      expect { subject.create_participant_role(other) }.to raise_error
    end
  end
  
    
  describe "#remove_participant_role" do
    subject { Fabricate(:event_participation, event: course, application: Fabricate(:event_application)) }

    before do
      Fabricate(course.participant_type.name.to_sym, participation: subject)
    end
        
    it "removes role for given application" do
      expect { subject.remove_participant_role }.to change { Event::Course::Role::Participant.count }.by(-1)
    end
    
    it "does not touch participation" do
      subject.remove_participant_role
      Event::Participation.where(id: subject.id).exists?.should be_true
    end
  end
end
