require 'spec_helper'

describe EventsController do

  context "event_course" do
    context "new" do

      let(:group) { groups(:top_group) }
      let(:date)  {{ label: 'foo', start_at_date: Date.today, finish_at_date: Date.today }}
      
      it "creates new event course with dates" do
  
        sign_in(people(:top_leader))

        post :create, event: {  group_id: group.id, 
                                name: 'foo', 
                                dates_attributes: [ date ],
                                contact_id: people(:top_leader).id,
                                type: 'Event::Course' }, 
                      group_id: group.id

        event = assigns(:event)
        require 'pry'
        binding.pry
        should redirect_to(group_event_path(group, event))
        event.should be_persisted
        event.dates.should have(1).item
        event.dates.first.should be_persisted

      end

      it "does not create event course if the user hasn't permission" do
        user = Fabricate(Group::BottomGroup::Leader.name.to_s, group: groups(:bottom_group_one_one))
        sign_in(user.person)

        post :create, event: {  group_id: group.id, 
                                name: 'foo', 
                                type: 'Event::Course' }, 
                      group_id: group.id

        should redirect_to(root_path)

      end

    end
  end
  


end
