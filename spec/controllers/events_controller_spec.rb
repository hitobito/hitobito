require 'spec_helper'

describe EventsController do

  context "event_course" do
    let(:group) { groups(:top_group) }
    let(:group2) { Fabricate(Group::TopGroup.name.to_sym, name: 'CCC', parent: groups(:top_layer)) }
    let(:group3) { Fabricate(Group::TopGroup.name.to_sym, name: 'AAA', parent: groups(:top_layer)) }
    
    before { group2 }
    
    context "GET new" do
      it "loads sister groups" do
        sign_in(people(:top_leader))
        group3
        
        get :new, group_id: group.id, event: { type: 'Event' }
        
        assigns(:groups).should == [group3, group2]
      end
    end
    
    context "POST create" do
      let(:date)  {{ label: 'foo', start_at_date: Date.today, finish_at_date: Date.today }}
      let(:question)  {{ question: 'foo?', choices: '1,2,3,4' }}
      
      it "creates new event course with dates" do
        sign_in(people(:top_leader))

        post :create, event: {  group_ids: [group.id, group2.id], 
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
        
        event.group_ids.should =~ [group.id, group2.id]
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
