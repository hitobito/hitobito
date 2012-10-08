require 'spec_helper'

describe Ability::Events do
  
  let(:person)  { role.person }
  let(:group)   { role.group }
  let(:event)   { Fabricate(:event, group: group) }
  
  subject { Ability.new(person.reload) }

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
        should be_able_to(:index_people, event)
      end
      
      it "may not update event in other layer" do
        other = Fabricate(:event, group: groups(:bern))
        should_not be_able_to(:update, other)
      end
      
      it "may not index people for event in his layer" do
        other = Fabricate(:event, group: groups(:bern))
        should_not be_able_to(:index_people, other)
      end
      
    end
    
    
    context Event::Participation do
      let(:participation) { Fabricate(Event::Participation::Participant.name.to_sym, event: event) }
      
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
      
      it "may not show participation in event from other layer" do
        other = Fabricate(Event::Participation::Participant.name.to_sym, event: Fabricate(:event, group: groups(:bern)))
        should_not be_able_to(:show, other)
      end
    end
    
    context Event::Application do 
      let(:application) { Fabricate(:event_application, priority_1: event) }
      
      it "may create new application for anybody" do
        should be_able_to(:create, application)
      end
      
      it "may show application" do
        should be_able_to(:show, application)
      end
      
      it "may update application" do
        should be_able_to(:update, application)
      end
      
      it "may not update applications of other groups" do
        other = Fabricate(:event_application, priority_1: Fabricate(:course, group: groups(:no)))
        should_not be_able_to(:update, other)
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
        should be_able_to(:index_people, event)
      end
      
      it "may not update event in other group" do
        other = Fabricate(:event, group: groups(:be_agency))
        should_not be_able_to(:update, other)
      end
      
      it "may not index people for event in other group" do
        other = Fabricate(:event, group: groups(:be_agency))
        should_not be_able_to(:index_people, other)
      end
    end
    
    context Event::Participation do
      let(:participation) { Fabricate(Event::Participation::Participant.name.to_sym, event: event) }
      
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
        other = Fabricate(Event::Participation::Participant.name.to_sym, event: Fabricate(:event, group: groups(:be_agency)))
        should_not be_able_to(:show, other)
      end
    end
    
    context Event::Application do 
      let(:application) { Fabricate(:event_application, priority_1: event) }
      
      it "may create new application for anybody" do
        should be_able_to(:create, application)
      end
      
      it "may show application" do
        should be_able_to(:show, application)
      end
      
      it "may update application" do
        should be_able_to(:update, application)
      end
      
      it "may not update applications of other groups" do
        other = Fabricate(:event_application, priority_1: Fabricate(:course, group: groups(:no)))
        should_not be_able_to(:update, other)
      end
    end
  end
      
  context :event_full do
    let(:group)  { groups(:be) }
    let(:role)   { Fabricate(Group::StateBoard::Member.name.to_sym, group: groups(:be_board)) }
    let(:participation) { Fabricate(Event::Participation::Leader.name.to_sym, event: event, person: role.person)}
    let(:person) { participation.person }
    
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
        should be_able_to(:index_people, event)
      end
      
      it "may not update other event" do
        other = Fabricate(:event, group: group)
        should_not be_able_to(:update, other)
      end
      
      it "may not index people for other event" do
        other = Fabricate(:event, group: group)
        should_not be_able_to(:index_people, other)
      end
      
    end
    
    context Event::Participation do
      let(:other) { Fabricate(Event::Participation::Participant.name.to_sym, event: event) }
      
      it "may show participation" do
        should be_able_to(:show, other)
      end
      
      it "may create participation" do
        should be_able_to(:create, other)
      end
      
      it "may update participation" do
        should be_able_to(:update, other)
      end
      
      it "may destroy participation" do
        should be_able_to(:destroy, other)
      end
      
      it "may not show participation in other event" do
        other = Fabricate(Event::Participation::Participant.name.to_sym, event: Fabricate(:event, group: group))
        should_not be_able_to(:show, other)
      end
      
      it "may not update participation in other event" do
        other = Fabricate(Event::Participation::Participant.name.to_sym, event: Fabricate(:event, group: group))
        should_not be_able_to(:update, other)
      end
    end
    
    context Event::Application do 
      let(:application) { Fabricate(:event_application, priority_1: event) }
      
      it "may not create new application for anybody" do
        should_not be_able_to(:create, application)
      end
      
      it "may show application" do
        should be_able_to(:show, application)
      end
      
      it "may not update application" do
        should_not be_able_to(:update, application)
      end
      
      it "may not show applications of other events" do
        other = Fabricate(:event_application, priority_1: Fabricate(:course, group: group))
        should_not be_able_to(:show, other)
      end
    end
  end
  
  context :event_contact_data do 
    let(:role)   { Fabricate(Group::StateBoard::Member.name.to_sym, group: groups(:be_board)) }
    let(:event)  { Fabricate(:event, group: groups(:be)) }
    let(:participation) { Fabricate(Event::Participation::Cook.name.to_sym, event: event, person: role.person) }
    let(:person) { participation.person }
          
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
        should be_able_to(:index_people, event)
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
        should_not be_able_to(:index_people, other)
      end
      
    end
    
    context Event::Participation do
      it "may show his participation" do
        should be_able_to(:show, participation)
      end
      
      it "may show other participation" do
        other = Fabricate(Event::Participation::Participant.name.to_sym, event: event)
        should be_able_to(:show, other)
      end
      
      it "may not show participation in other event" do
        other = Fabricate(Event::Participation::Participant.name.to_sym, event: Fabricate(:event, group: group))
        should_not be_able_to(:show, other)
      end
      
      it "may update his participation" do
        should be_able_to(:update, participation)
      end
      
      it "may not update other participation" do
        other = Fabricate(Event::Participation::Participant.name.to_sym, event: event)
        should_not be_able_to(:update, other)
      end
    end
    
    context Event::Application do 
      let(:application) { Fabricate(:event_application, priority_1: event) }
      
      it "may not create new application for anybody" do
        should_not be_able_to(:create, application)
      end
      
      it "may not show application" do
        should_not be_able_to(:show, application)
      end
      
      it "may update application" do
        should_not be_able_to(:update, application)
      end
      
      it "may show his application" do
        application.participation.person = person
        should be_able_to(:show, application)
      end
      
      it "may update his application" do
        application.participation.person = person
        should be_able_to(:update, application)
      end
      
      it "may create his application" do
        application.participation.person = person
        should be_able_to(:create, application)
      end
    end
  end
  
  context :in_same_hierarchy do
    let(:role) { Fabricate(Group::Flock::Guide.name.to_sym, group: groups(:bern)) }
    
    context Event::Application do 
      let(:application) do
        appl =  Fabricate(:event_application, priority_1: event)
        appl.participation.person = person
        appl
      end

      it "may create his application" do
        should be_able_to(:create, application)
      end
      
      it "may show his application" do
        should be_able_to(:show, application)
      end
      
      it "may update his application" do
        should be_able_to(:update, application)
      end
      
    end
  end
  
  context :in_other_hierarchy do
    let(:role)  { Fabricate(Group::Flock::Guide.name.to_sym, group: groups(:innerroden)) }
    let(:event) { Fabricate(:course, group: groups(:be)) }
    
    context Event::Application do 
      let(:application) do
        appl =  Fabricate(:event_application, priority_1: event)
        appl.participation.person = person
        appl
      end

      it "may not create his application" do
        should_not be_able_to(:create, application)
      end
      
      it "may show his application" do
        should be_able_to(:show, application)
      end
      
      it "may update his application" do
        should be_able_to(:update, application)
      end
      
    end
  end
  
  context :admin do
    let(:role) { Fabricate(Group::FederalBoard::Member.name.to_sym, group: groups(:federal_board)) }
    
    it "may manage event kinds" do
      should be_able_to(:manage, Event::Kind)
    end
  end

end
