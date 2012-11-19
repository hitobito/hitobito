require 'spec_helper_request'

describe Event::QualificationsController do
  
  let(:event) do
    event = Fabricate(:course, kind: event_kinds(:slk))
    event.dates.create!(start_at: 10.days.ago, finish_at: 5.days.ago)
    event
  end
  
  let(:group) { event.groups.first }
  
  let(:participant_1)  do
    participation = Fabricate(:event_participation, event: event)
    Fabricate(Event::Course::Role::Participant.name.to_sym, participation: participation)
    participation
  end
  
  let(:participant_2)  do
    participation = Fabricate(:event_participation, event: event)
    Fabricate(Event::Course::Role::Participant.name.to_sym, participation: participation)
    participation
  end
  
  before do
    # init required data
    participant_1
    participant_2
    
    sign_in
    visit group_event_qualifications_path(group.id, event.id)
  end
  
  it "qualification requests are mutually undoable", js: true do
    appl_id = "#event_participation_#{participant_1.id}"
      
    find("#{appl_id} td:first").should have_selector('.icon-minus')
    
    find("#{appl_id} td:first a").trigger('click')
    find("#{appl_id} td:first").should have_selector('.icon-ok')
      
    find("#{appl_id} td:first a").trigger('click')
    find("#{appl_id} td:first").should have_selector('.icon-minus')
  end
  
end
