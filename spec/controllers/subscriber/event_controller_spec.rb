# encoding: UTF-8
require 'spec_helper'
describe Subscriber::EventController do

  before { sign_in(person) }

  let(:now) { Time.zone.now }
  let(:group) { groups(:top_group) }
  let(:person) { people(:top_leader) }
  let(:list) { Fabricate(:mailing_list, group: group) }

  context "GET query" do
    subject { response.body }

    context "returns event and group name" do
      before do
        create_event('event', now)

        get :query, q: 'event', group_id: group.id, mailing_list_id: list.id
      end

      it { should =~ /event &gt; TopGroup/ }
    end

    context "lists events from previous year onwards" do
      before do
        create_event('event now', now)
        create_event('event later', now + 5.minutes)
        create_event('event last_year', now - 1.year)
        create_event('event two_years_ago', now - 5.years)

        get :query, q: 'event', group_id: group.id, mailing_list_id: list.id
      end

      it { should =~ /now/ }
      it { should =~ /later/ }
      it { should =~ /last_year/ }
      it { should_not =~ /two_years_ago/ }
    end

    context "list only events from self, sister and descendants" do
      let(:group) { groups(:bottom_layer_one) }
      let(:person) { Fabricate(Group::BottomLayer::Leader.name.to_s, group: group).person }

      before do
        create_event('event', now)
        create_event('event', now, groups(:bottom_group_one_one))
        create_event('event', now, groups(:bottom_group_two_one))
        create_event('event', now, groups(:bottom_layer_two))
        create_event('event', now, groups(:top_group))

        get :query, q: 'event', group_id: group.id, mailing_list_id: list.id
      end

      it { should =~ %r{#{groups(:bottom_group_one_one).name}} }
      it { should =~ %r{#{groups(:bottom_group_two_one).name}} }
      it { should =~ %r{#{groups(:bottom_layer_two).name}} }
      it { should_not =~ %r{#{groups(:top_group).name}} }
    end

    context "finds by group name" do
      before do
        create_event('foobar', now)

        get :query, q: 'Top Group', group_id: group.id, mailing_list_id: list.id
      end

      it { should =~ /foobar/ }
    end

    context "finds by event kind" do
      before do
        course = Fabricate(:course, name: 'foobar', groups: [group])
        Fabricate(:event_date, event: course, start_at: now)

        get :query, q: 'Scharleiter', group_id: group.id, mailing_list_id: list.id
      end

      it { should =~ /foobar/ }
    end
  end

  context "POST create" do

    it "without subscriber_id replaces error" do
      post :create, group_id: group.id,
                    mailing_list_id: list.id

      should render_template('crud/new')
      assigns(:subscription).errors.should have(1).item
      assigns(:subscription).errors[:base].should eq ["Anlass muss ausgewählt werden"]
    end

    it "duplicated subscription replaces error" do
      subscription = list.subscriptions.build
      subscription.update_attribute(:subscriber, events(:top_event))

      expect { post :create, group_id: group.id, mailing_list_id: list.id,
               subscription: { subscriber_id: events(:top_event).id } }.not_to change(Subscription, :count)

      should render_template('crud/new')
      assigns(:subscription).errors.should have(1).item
      assigns(:subscription).errors[:base].should eq ["Anlass wurde bereits hinzugefügt"]
    end
  end


  def create_event(name, start_at, event_group=group)
    event = Fabricate(:event, name: name, groups: [event_group])
    event.dates.first.update_attribute(:start_at, start_at)
  end

end

