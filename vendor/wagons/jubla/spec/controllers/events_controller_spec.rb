require 'spec_helper'

describe EventsController do

  context "event_course" do
    context "new" do

      let(:group) { groups(:ch) }
      let(:date)  {{ label: 'foo', start_at_date: Date.today, finish_at_date: Date.today }}
      let(:leader) { Fabricate(Group::FederalBoard::Member.name.to_sym, group: groups(:federal_board)).person }
      let(:contact) { Person.first }
      let(:advisor) { Person.last }

      # TODO: add questions
      
      it "creates new event course with dates,advisor" do
  
        sign_in(leader)
        post :create, event: {  group_id: group.id, 
                                name: 'foo', 
                                dates_attributes: [ date ],
                                contact_id: contact.id,
                                advisor_id: advisor.id,
                                type: 'Event::Course' }, 
                      group_id: group.id


        event = assigns(:event)

        should redirect_to(group_event_path(group, event))

        event.should be_persisted
        event.dates.should have(1).item
        event.dates.first.should be_persisted
        event.contact.should eq contact
        event.advisor.should eq advisor

      end
      
      it "creates new event course without contact,dates,advisor" do
  
        sign_in(leader)
        post :create, event: {  group_id: group.id, 
                                name: 'foo', 
                                contact_id: '',
                                advisor_id: '',
                                type: 'Event::Course' }, 
                      group_id: group.id

        event = assigns(:event)

        should redirect_to(group_event_path(group, event))
        event.should be_persisted

      end

    end
  end
  


end
