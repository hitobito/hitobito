require 'spec_helper'

describe Event do
  
  subject do
    event = Fabricate(:event, group: groups(:top_group) )
    Fabricate(Event::Participation::Leader.name.to_sym, event: event)
    Fabricate(Event::Participation::Participant.name.to_sym, event: event)
    p = Fabricate(:person)
    Fabricate(Event::Participation::Participant.name.to_sym, event: event, person: p)
    Fabricate(Event::Participation::Participant.name.to_sym, event: event, label: 'Irgendwas', person: p)
    event
  end
  
  
  its(:participant_count) { should == 2 }
  
end
