require 'spec_helper'

describe Ability::Events do
  
  let(:user)    { role.person }
  let(:group)   { role.group }
  let(:event)   { Fabricate(:event, group: group) }
  
  subject { Ability.new(user.reload) }

  context :layer_full do
    let(:role) { Fabricate(Group::StateAgency::Leader.name.to_sym, group: groups(:be_agency)) }
    
    context Event do
      it "may create event in his group" do
        should be_able_to(:create, group.events.new)
      end
      
      it "may create event in his layer" do
        should be_able_to(:create, groups(:be).events.new)
      end
      
      it "may update event in his layer" do
        should be_able_to(:update, event)
      end
      
      it "may index people for event in his layer" do
        should be_able_to(:index_participations, event)
      end
      
      it "may update event in lower layer" do
        other = Fabricate(:event, group: groups(:bern))
        should be_able_to(:update, other)
      end
      
      it "may not update event in other layer" do
        other = Fabricate(:event, group: groups(:no))
        should_not be_able_to(:update, other)
      end
      
      it "may index people for event in lower layer" do
        other = Fabricate(:event, group: groups(:bern))
        should be_able_to(:index_participations, other)
      end
      
      it "may not index people for event in other layer" do
        other = Fabricate(:event, group: groups(:no))
        should_not be_able_to(:index_participations, other)
      end
    end
    
    
    context Event::Participation do
      let(:participation) { Fabricate(:event_participation, event: event) }
      before { Fabricate(Event::Role::Participant.name.to_sym, participation: participation) }
      
      it "may show participation" do
        should be_able_to(:show, participation)
      end
      
      it "may create participation" do
        should be_able_to(:create, participation)
      end
      
      it "may update participation" do
        should be_able_to(:update, participation)
      end
      
      it "may destroy participation" do
        should be_able_to(:destroy, participation)
      end
      
      it "may show participation in event from lower layer" do
        other = Fabricate(:event_participation, event: Fabricate(:event, group: groups(:bern)))
        should be_able_to(:show, other)
      end
      
      it "may not show participation in event from other layer" do
        other = Fabricate(:event_participation, event: Fabricate(:event, group: groups(:no)))
        should_not be_able_to(:show, other)
      end
    end

  end
  
  context :group_full do
    let(:role) { Fabricate(Jubla::Role::GroupAdmin.name.to_sym, group: groups(:be_board)) }
    
    context Event do
      it "may create event in his group" do
        should be_able_to(:create, group.events.new)
      end
      
      it "may update event in his group" do
        should be_able_to(:update, event)
      end
      
      it "may destroy event in his group" do
        should be_able_to(:destroy, event)
      end
      
      it "may index people for event in his layer" do
        should be_able_to(:index_participations, event)
      end
      
      it "may not update event in other group" do
        other = Fabricate(:event, group: groups(:be_agency))
        should_not be_able_to(:update, other)
      end
      
      it "may not index people for event in other group" do
        other = Fabricate(:event, group: groups(:be_agency))
        should_not be_able_to(:index_participations, other)
      end
    end
    
    context Event::Participation do
      let(:participation) { Fabricate(:event_participation, event: event) }
      before { Fabricate(Event::Role::Participant.name.to_sym, participation: participation) }
      
      it "may show participation" do
        should be_able_to(:show, participation)
      end
      
      it "may create participation" do
        should be_able_to(:create, participation)
      end
      
      it "may update participation" do
        should be_able_to(:update, participation)
      end
      
      it "may destroy participation" do
        should be_able_to(:destroy, participation)
      end
      
      it "may not show participation in event from other group" do
        other = Fabricate(:event_participation, event: Fabricate(:event, group: groups(:be_agency)))
        should_not be_able_to(:show, other)
      end
    end

  end
      
  context :event_full do
    let(:group)  { groups(:be) }
    let(:role)   { Fabricate(Group::StateBoard::Member.name.to_sym, group: groups(:be_board)) }
    let(:participation) { Fabricate(:event_participation, event: event, person: user)}
    
    before { Fabricate(Event::Role::Leader.name.to_sym, participation: participation) } 
    
    context Event do
      it "may not create events" do
        should_not be_able_to(:create, group.events.new)
      end
      
      it "may update his event" do
        should be_able_to(:update, event)
      end
      
      it "may not destroy his event" do
        should_not be_able_to(:destroy, event)
      end
      
      it "may index people his event" do
        should be_able_to(:index_participations, event)
      end
      
      it "may not update other event" do
        other = Fabricate(:event, group: group)
        should_not be_able_to(:update, other)
      end
      
      it "may not index people for other event" do
        other = Fabricate(:event, group: group)
        should_not be_able_to(:index_participations, other)
      end
      
    end
    
    context Event::Participation do
      let(:other) { Fabricate(:event_participation, event: event) }
      before { Fabricate(Event::Role::Participant.name.to_sym, participation: other) }
      
      it "may show participation" do
        should be_able_to(:show, other)
      end
      
      it "may not create participation" do
        should_not be_able_to(:create, other)
      end
      
      it "may update participation" do
        should be_able_to(:update, other)
      end
      
      it "may not destroy participation" do
        should_not be_able_to(:destroy, other)
      end
      
      it "may not show participation in other event" do
        other = Fabricate(:event_participation, event: Fabricate(:event, group: group))
        should_not be_able_to(:show, other)
      end
      
      it "may not update participation in other event" do
        other = Fabricate(:event_participation, event: Fabricate(:event, group: group))
        should_not be_able_to(:update, other)
      end
    end

  end
  
  context :event_contact_data do 
    let(:role)   { Fabricate(Group::StateBoard::Member.name.to_sym, group: groups(:be_board)) }
    let(:event)  { Fabricate(:event, group: groups(:be)) }
    let(:participation) { Fabricate(:event_participation, event: event, person: user) }
    
    before { Fabricate(Event::Role::Cook.name.to_sym, participation: participation) } 
          
    context Event do
      it "may show his event" do
        should be_able_to(:show, event)
      end
      
      it "may not create events" do
        should_not be_able_to(:create, groups(:be).events.new)
      end
      
      it "may not update his event" do
        should_not be_able_to(:update, event)
      end
      
      it "may not destroy his event" do
        should_not be_able_to(:destroy, event)
      end
      
      it "may index people for his event" do
        should be_able_to(:index_participations, event)
      end
      
      it "may show other event" do
        other = Fabricate(:event, group: groups(:be))
        should be_able_to(:show, other)
      end
      
      it "may not update other event" do
        other = Fabricate(:event, group: groups(:be))
        should_not be_able_to(:update, other)
      end
      
      it "may not index people for other event" do
        other = Fabricate(:event, group: groups(:be))
        should_not be_able_to(:index_participations, other)
      end
      
    end

    context Event::Participation do
      it "may show his participation" do
        should be_able_to(:show, participation)
      end
      
      it "may show other participation" do
        other = Fabricate(:event_participation, event: event)
        Fabricate(Event::Role::Participant.name.to_sym, participation: other)
        should be_able_to(:show, other)
      end
      
      it "may not show details of other participation" do
        other = Fabricate(:event_participation, event: event)
        Fabricate(Event::Role::Participant.name.to_sym, participation: other)
        should_not be_able_to(:show_details, other)
      end
      
      it "may not show participation in other event" do
        other = Fabricate(:event_participation, event: Fabricate(:event, group: group))
        Fabricate(Event::Role::Participant.name.to_sym, participation: other)
        should_not be_able_to(:show, other)
      end
      
      it "may not update his participation" do
        should_not be_able_to(:update, participation)
      end
      
      it "may not update other participation" do
        other = Fabricate(:event_participation, event: event)
        Fabricate(Event::Role::Participant.name.to_sym, participation: other)
        should_not be_able_to(:update, other)
      end
    end
  
  end
  
  context :in_same_hierarchy do
    let(:role) { Fabricate(Group::Flock::Guide.name.to_sym, group: groups(:bern)) }
    let(:participation) { Fabricate(:event_participation, person: user, event: event) }
        
        
     context Event::Participation do 
      it "may create his participation" do
        p = event.participations.new
        p.person_id = user.id
        should be_able_to(:create, p)
      end
      
      it "may show his participation" do
        should be_able_to(:show, participation)
      end
      
      it "may not update his participation" do
        should_not be_able_to(:update, participation)
      end
      
    end

  end
  
  context :in_other_hierarchy do
    let(:role)  { Fabricate(Group::Flock::Guide.name.to_sym, group: groups(:innerroden)) }
    let(:event) { Fabricate(:course, group: groups(:be)) }
    let(:participation) { Fabricate(:event_participation, person: user, event: event) }
        
    context Event::Participation do 
      it "may create his participation" do
        should be_able_to(:create, participation)
      end
      
      it "may show his participation" do
        should be_able_to(:show, participation)
      end
      
      it "may not update his participation" do
        should_not be_able_to(:update, participation)
      end
    end
    
  end
  
  context :admin do
    let(:role) { Fabricate(Group::FederalBoard::Member.name.to_sym, group: groups(:federal_board)) }
    
    it "may manage event kinds" do
      should be_able_to(:manage, Event::Kind)
    end
  end


  context :only_bulei_can_edit_closed_events do
    let(:course) { Fabricate(:course, group: groups(:be), state: 'closed') }
    let(:event) { Fabricate(:event, group: groups(:be), state: 'closed') }

    context :bulei do
      let(:role) { Fabricate(Group::FederalBoard::Member.name.to_sym, group: groups(:federal_board)) }
      it "can update course" do
        should be_able_to(:update, course)
      end
      it "can update event" do
        should be_able_to(:update, event)
      end
    end

    context :ast do
      let(:role) { Fabricate(Group::StateAgency::Leader.name.to_sym, group: groups(:be_agency)) }
      it "cannot update course" do
        should_not be_able_to(:update, course)
      end
      it "can update event" do
        should be_able_to(:update, event)
      end
    end
  end

end
