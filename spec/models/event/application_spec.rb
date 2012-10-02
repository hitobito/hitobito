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
end


