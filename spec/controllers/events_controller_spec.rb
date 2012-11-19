require 'spec_helper'

describe EventsController do

  context "event_course" do
    context "new" do

      let(:group) { groups(:top_group) }
      let(:date)  {{ label: 'foo', start_at_date: Date.today, finish_at_date: Date.today }}
      let(:question)  {{ question: 'foo?', choices: '1,2,3,4' }}
      
      it "creates new event course with dates" do
        sign_in(people(:top_leader))

        post :create, event: {  group_ids: [group.id], 
                                name: 'foo', 
                                kind_id: event_kinds(:slk).id,
                                dates_attributes: [ date ],
                                questions_attributes: [ question ],
                                contact_id: people(:top_leader).id,
                                type: 'Event::Course' }, 
                      group_id: group.id

        event = assigns(:event)
        should redirect_to(group_event_path(group, event))
        event.should be_persisted
        event.dates.should have(1).item
        event.dates.first.should be_persisted
        event.questions.should have(1).item
        event.questions.first.should be_persisted

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
