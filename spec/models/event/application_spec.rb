require 'spec_helper'

describe Event::Application do
  
  let(:course) do
    course = Fabricate(:course, group: groups(:top_layer))
    course.questions << Fabricate(:event_question, event: course)
    course.questions << Fabricate(:event_question, event: course)
    course
  end
  
  subject { Event::Application.new }

  context "assignment of prio 1" do
    
    context do
      before { subject.priority_1 = course }
      
      it "creates a new participation" do
        subject.participation.type.should == course.participant_type.sti_name
      end
      
      it "creates answers from event" do
        subject.participation.answers.collect(&:question).to_set.should == course.questions.to_set
      end
    end
    
    it "does not save associations in database" do
      expect { subject.priority_1 = course }.not_to change { Event::Application.count }
      expect { subject.priority_1 = course }.not_to change { Event::Answer.count }
      expect { subject.priority_1 = course }.not_to change { Event::Participation.count }
    end
  end
  
  context "mass assignments" do
    before { subject.priority_1 = course }
    
    it "assigns participation and answers for new record" do
      q = course.questions
      subject.participation.person_id = 42
      subject.attributes = {participation_attributes: 
            {additional_information: 'bla',
             answers_attributes: [{question_id: q[0].id, answer: 'ja'},
                                  {question_id: q[1].id, answer: 'nein'}]}}
      
      p = subject.participation
      p.additional_information.should == 'bla'
      p.answers.should have(2).items
    end
    
    it "assigns participation and answers for persisted record" do
      p = Person.first
      subject.participation.person = p
      subject.save!
      
      q = course.questions
      subject.attributes = {participation_attributes: 
            {additional_information: 'bla',
             answers_attributes: [{question_id: q[0].id, answer: 'ja'},
                                  {question_id: q[1].id, answer: 'nein'}]}}
      
      p = subject.participation
      p.person_id.should == p.id
      p.additional_information.should == 'bla'
      p.answers.should have(2).items
    end
  end
end


