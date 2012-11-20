require 'spec_helper'

describe Event::RolesController do
  
  let(:group) { groups(:top_layer) }
  
  let(:course) do
    course = Fabricate(:course, groups: [group])
    course.questions << Fabricate(:event_question, event: course)
    course.questions << Fabricate(:event_question, event: course)
    course
  end
  
  let(:user) { people(:top_leader) }
  
  before { sign_in(user) }
  
  context "GET new" do
    before { get :new, group_id: group.id, event_id: course.id, event_role: { type: Event::Role::Leader.sti_name } }
    
    it "builds participation with answers" do
      role = assigns(:role)
      participation = role.participation
      participation.event_id.should == course.id
      participation.answers.should have(2).items
    end
    
  end
  
  context "POST create" do
    
    context "without participation" do
           
     it "creates role and participation" do
        post :create, group_id: group.id, event_id: course.id, event_role: { type: Event::Role::Leader.sti_name, person_id: user.id }
       
        role = assigns(:role)
        role.should be_persisted
        role.should be_kind_of(Event::Role::Leader)
        participation = role.participation
        participation.event_id.should == course.id
        participation.person_id.should == user.id
        participation.answers.should have(2).items
      end
    end
    
    context "with existing participation" do
      let (:participation) { Fabricate(:event_participation, event: course, person: user) }
      before do
        role = Event::Role::Cook.new
        role.participation = participation
        role.save!
      end
            
      it "creates role and participation" do
        expect {
        post :create, group_id: group.id, event_id: course.id, event_role: { type: Event::Role::Leader.sti_name, person_id: user.id }
        }.to change { Event::Participation.count }.by(0)
        
        role = assigns(:role)
        role.should be_persisted
        role.should be_kind_of(Event::Role::Leader)
        role.participation.should == participation
        participation.answers.should have(0).items # o items as we didn't create any in the before block
      end
    end
    
  end
    
end
