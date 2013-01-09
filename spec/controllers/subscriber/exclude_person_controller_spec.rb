# encoding: UTF-8
require 'spec_helper'

describe Subscriber::ExcludePersonController do

  before { sign_in(person) }

  let(:group) { groups(:top_group) }
  let(:person) { people(:top_leader) }
  let(:list) { Fabricate(:mailing_list, group: group) }

  context "POST create" do

    context "with existing subscription" do

      it "destroys subscription" do
        Fabricate(:subscription, mailing_list: list, subscriber: person)

        expect do
          post :create, group_id: group.id, mailing_list_id: list.id,
            subscription: { subscriber_id: person.id }
        end.to change(Subscription, :count).by(-1)
        flash[:notice].should eq "Abonnent #{person} wurde erfolgreich ausgeschlossen"
      end

      it "creates exclusion" do
        event = Fabricate(:event_participation, person: person, active: true).event
        Fabricate(:subscription, mailing_list: list, subscriber: event)

        expect do
          post :create, group_id: group.id, mailing_list_id: list.id,
            subscription: { subscriber_id: person.id }
        end.to change(Subscription, :count).by(1)
        flash[:notice].should eq "Abonnent #{person} wurde erfolgreich ausgeschlossen"
      end

      after do
        list.subscribed?(person).should be_false
      end
    end


    it "without subscriber_id replaces error" do
      post :create, group_id: group.id, mailing_list_id: list.id

      should render_template('subscriber/exclude_person/new')
      assigns(:subscription).errors.should have(1).item
      assigns(:subscription).errors[:base].should eq ["Person muss ausgewählt werden"]
    end

    it "without valid subscriber_id replaces error" do
      other = Fabricate(:person)
      post :create, group_id: group.id, mailing_list_id: list.id,
        subscription: { subscriber_id: other.id }


      should render_template('subscriber/exclude_person/new')
      assigns(:subscription).errors.should have(1).item
      assigns(:subscription).errors[:base].should eq ["#{other} ist kein Abonnent"]
    end

    it "duplicated subscription replaces error" do
      subscription = list.subscriptions.build
      subscription.update_attribute(:subscriber, person)
      subscription.update_attribute(:excluded, true)

      expect { post :create, group_id: group.id, mailing_list_id: list.id,
               subscription: { subscriber_id: person.id } }.not_to change(Subscription, :count)

      should render_template('subscriber/exclude_person/new')
      assigns(:subscription).errors.should have(1).item
      assigns(:subscription).errors[:base].should eq ["#{person} ist kein Abonnent"]
    end
  end
end
