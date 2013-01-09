# encoding: UTF-8
require 'spec_helper'
describe Subscriber::UserController do

  before { sign_in(person) }

  let(:group) { groups(:top_group) }
  let(:person) { people(:top_leader) }
  let(:list) { Fabricate(:mailing_list, group: group, subscribable: true) }

  context "POST create" do
    it "creates new subscription" do
      expect { post :create, group_id: group.id, mailing_list_id: list.id }.to change(Subscription, :count).by(1)
    end

    it "creates new subscription only once" do
      Fabricate(:subscription, mailing_list: list, subscriber: person)

      expect { post :create, group_id: group.id, mailing_list_id: list.id }.not_to change(Subscription, :count)
    end

    it "updates excluded subscription" do
      subscription = Fabricate(:subscription, mailing_list: list, subscriber: person, excluded: true)
      subscription.should be_excluded
      expect { post :create, group_id: group.id, mailing_list_id: list.id }.not_to change(Subscription, :count)

      subscription.reload.should_not be_excluded
    end

    after do
      flash[:notice].should eq "Abonnent Top Leader wurde erfolgreich erstellt"
      should redirect_to group_mailing_list_path(group_id: list.group.id, id: list.id)
    end
  end


  context "POST destroy" do
    it "creates exclusion when no subscription exists" do
      expect { post :destroy, group_id: group.id, mailing_list_id: list.id }.to change(Subscription, :count).by(1)

      person.subscriptions.last.should be_excluded
    end

    it "does not create exclusion twice" do
      subscription = Fabricate(:subscription, mailing_list: list, subscriber: person, excluded: true)

      expect { post :destroy, group_id: group.id, mailing_list_id: list.id }.not_to change(Subscription, :count)
      person.subscriptions.last.should be_excluded
    end

    after do
      flash[:notice].should eq "Abonnent Top Leader wurde erfolgreich ausgeschlossen"
      should redirect_to group_mailing_list_path(group_id: list.group.id, id: list.id)
    end
  end

end

