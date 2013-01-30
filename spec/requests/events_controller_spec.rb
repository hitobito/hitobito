# encoding: UTF-8
require 'spec_helper_request'

describe EventsController, js: true do
  
  let(:event) do
    event = Fabricate(:course, kind: event_kinds(:slk), groups: [groups(:top_group)])
    event.dates.create!(start_at: 10.days.ago, finish_at: 5.days.ago)
    event
  end
  
  
  it "may set and remove contact from event" do
    obsolete_node_safe do
      sign_in
      visit edit_group_event_path(event.group_ids.first, event.id)
     
      # set contact
      fill_in "Kontaktperson", with: "Top"
      find('.typeahead.dropdown-menu').should have_content 'Top Leader'
      find('.typeahead.dropdown-menu').click
      click_button 'Speichern'
      
      # show event
      find('aside').should have_content 'Kontakt'
      find('aside').should have_content 'Top Leader'
      click_link 'Bearbeiten'
      
      # remove contact
      find('#event_contact').value.should == 'Top Leader'
      fill_in "Kontaktperson", with: ""
      click_button 'Speichern'
      
      # show event again
      should_not have_selector('.contactable')
    end
  end
  
end
