require 'spec_helper'

describe Event::ParticipationsController do
  
  let(:course) do
    course = Fabricate(:course, group: groups(:ch), priorization: true)
    course.questions << Fabricate(:event_question, event: course)
    course.questions << Fabricate(:event_question, event: course)
    course.dates << Fabricate(:event_date, event: course)
    course
  end
  
  let(:other_course) do 
    other = Fabricate(:course, group: course.group, kind: course.kind)
    other.dates << Fabricate(:event_date, event: other, start_at: course.dates.first.start_at)
    other
  end
  
  let(:participation) do
    p = Fabricate(:event_participation, event: course, application: Fabricate(:event_application, priority_2: Fabricate(:course, kind: course.kind)))
    p.answers.create!(question_id: course.questions[0].id, answer: 'juhu')
    p.answers.create!(question_id: course.questions[1].id, answer: 'blabla')
    p
  end
  
  
  let(:user) { people(:top_leader) }
  
  before { sign_in(user); other_course }
  

  context "GET index" do
    before { @leader, @advisor, @participant = *create(Event::Role::Leader, 
                                                       Jubla::Event::Course::Role::Advisor, 
                                                       course.participant_type) }
    
    it "lists participant and leader group by default without advisor" do
      get :index, event_id: course.id
      assigns(:participations).should eq [@leader, @participant]
    end

    it "lists only leader_group without advisor" do
      get :index, event_id: course.id, filter: :leaders
      assigns(:participations).should eq [@leader]
    end

    it "lists only participant_group" do
      get :index, event_id: course.id, filter: :participants
      assigns(:participations).should eq [@participant]
    end

    def create(*roles)
      roles.map do |role_class|
        role = Fabricate(:event_role, type: role_class.name.to_sym)
        Fabricate(:event_participation, event: course, roles: [role], active: true)
      end
    end
  end


end
