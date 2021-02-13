require "spec_helper"

describe MailchimpSynchronizationsController do
  before { sign_in(user) }

  let(:user) { people(:top_leader) }
  let(:group) { groups(:top_group) }
  let(:mailing_list) { Fabricate(:mailing_list, group: group) }

  context "POST create" do
    it "runs a delayed job." do
      expect {
        post :create, params: {group_id: group.id, mailing_list_id: mailing_list.id}
      }.to change(Delayed::Job, :count).by(1)
    end
  end
end
