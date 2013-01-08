# encoding: UTF-8
require 'spec_helper'

describe Subscriber::PersonController do

  before { sign_in(person) }

  let(:group) { groups(:top_group) }
  let(:person) { people(:top_leader) }
  let(:list) { Fabricate(:mailing_list, group: group) }

  context "POST create" do
    it "without subscriber_id replaces error" do
      post :create, group_id: group.id,
                    mailing_list_id: list.id

      should render_template('crud/new')
      assigns(:subscription).errors.should have(1).item
      assigns(:subscription).errors[:base].should eq ["Person muss ausgewählt werden"]
    end

    it "duplicated subscription replaces error" do
      subscription = list.subscriptions.build
      subscription.update_attribute(:subscriber, person)

      expect { post :create, group_id: group.id, mailing_list_id: list.id,
               subscription: { subscriber_id: person.id } }.not_to change(Subscription, :count)

      should render_template('crud/new')
      assigns(:subscription).errors.should have(1).item
      assigns(:subscription).errors[:base].should eq ["Person wurde bereits hinzugefügt"]
    end
  end
end
