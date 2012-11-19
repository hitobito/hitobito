require 'spec_helper'

describe EventsController do

  context "event_course" do

    before { sign_in(people(:top_leader)) }

    context "create with advisor" do

      let(:group) { groups(:ch) }
      let(:date)  {{ label: 'foo', start_at_date: Date.today, finish_at_date: Date.today }}
      let(:contact) { Person.first }
      let(:advisor) { Person.last }
      
      it "creates new event course with dates,advisor" do
        post :create, event: {  group_ids: [group.id], 
                                name: 'foo', 
                                kind_id: Event::Kind.find_by_short_name('SLK').id,
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
      
      it "creates new event course without contact,advisor" do
        post :create, event: {  group_ids: [group.id], 
                                name: 'foo', 
                                kind_id: Event::Kind.find_by_short_name('SLK').id,
                                contact_id: '',
                                advisor_id: '',
                                dates_attributes: [ date ],
                                type: 'Event::Course' }, 
                      group_id: group.id

        event = assigns(:event)

        should redirect_to(group_event_path(group, event))
        event.should be_persisted
      end

    end
  end
  
  context "event_camp" do

    before { sign_in(people(:flock_leader)) }

    context "create with coach" do

      let(:group) { groups(:innerroden) }
      let(:date)  {{ label: 'foo', start_at_date: Date.today, finish_at_date: Date.today }}
      let(:contact) { Person.first }
      let(:coach) { Person.last }

      it "creates new event camp with dates,coach" do
        post :create, event: {  group_ids: [group.id], 
                                name: 'foo', 
                                kind_id: Event::Kind.find_by_short_name('SLK').id,
                                dates_attributes: [ date ],
                                contact_id: contact.id,
                                coach_id: coach.id,
                                type: 'Event::Camp' }, 
                      group_id: group.id


        event = assigns(:event)

        should redirect_to(group_event_path(group, event))

        event.should be_persisted
        event.dates.should have(1).item
        event.dates.first.should be_persisted
        event.contact.should eq contact
        event.coach.should eq coach
      end
    end

    context "#new with default coach" do

      let(:flock) { groups(:innerroden) }
      let(:date)  {{ label: 'foo', start_at_date: Date.today, finish_at_date: Date.today }}
      let(:coach) { people(:top_leader) }

      it "#new event camp it should set default coach" do
        # assign flock coach
        Fabricate(:role, group: flock, type: 'Group::Flock::Coach', person: coach)

        get :new, event: {  group_ids: [flock.id], 
                             type: 'Event::Camp' }, 
                   group_id: flock.id

        event = assigns(:event)
        event.coach.should eq coach
      end

      it "#new event camp it should NOT set default coach" do
        # no flock coach assigned
        get :new, event: {  group_ids: [flock.id], 
                             type: 'Event::Camp' }, 
                   group_id: flock.id

        event = assigns(:event)
        event.coach.should be nil
      end
    end
  end

end
