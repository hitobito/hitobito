#  Copyright (c) 2017 Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Person::ImpersonationController do
  before do
    @ref = @request.env["HTTP_REFERER"] = root_path
    SeedFu.quiet = true
    SeedFu.seed [Rails.root.join("db", "seeds")]
  end

  let(:group) { groups(:top_layer) }
  let(:user) { people(:top_leader) }
  let(:bottom_member) { people(:bottom_member) }

  include ActiveJob::TestHelper

  context "POST" do
    before { sign_in(user) }

    it "impersonates user and sets origin_user" do
      post :create, params: {group_id: group.id, person_id: bottom_member.id}
      expect(controller.send(:origin_user)).to eq(user)
      expect(response).to redirect_to(request.env["HTTP_REFERER"])
    end

    it "impersonates user and create Log entry" do
      expect { post :create, params: {group_id: group.id, person_id: bottom_member.id} }
        .to change { PaperTrail::Version.count }.by 1
    end

    it "impersonates user and sends mail" do
      perform_enqueued_jobs do
        expect { post :create, params: {group_id: group.id, person_id: bottom_member.id} }
          .to change { ActionMailer::Base.deliveries.size }.by 1
      end
    end

    it "cannot impersonate unconfirmed user" do
      bottom_member.update!(confirmed_at: nil)
      post :create, params: {group_id: group.id, person_id: bottom_member.id}
      expect(controller.send(:origin_user)).to be_nil
      expect(response).to redirect_to(request.env["HTTP_REFERER"])
      expect(flash[:alert]).to eq "Die Person hat ihre E-Mail Adresse noch nicht bestätigt und kann somit nicht imitiert werden."
    end

    it "cannot impersonate user if current_user" do
      post :create, params: {group_id: group.id, person_id: user.id}
      expect(controller.send(:origin_user)).to be_nil
      expect(response).to redirect_to(request.env["HTTP_REFERER"])
      expect(flash).to be_empty
    end

    it "user without permission cannot impersonate user" do
      post :create, params: {group_id: groups(:bottom_layer_one), person_id: people(:bottom_member)}
      expect(response.status).to be(302)
    end
  end

  context "DELETE" do
    before do
      sign_in(people(:bottom_member))
    end

    it "returns to origin user and creates log entry" do
      session[:origin_user] = people(:top_leader).id
      expect { delete :destroy, params: {group_id: group.id, person_id: people(:bottom_member).id} }
        .to change { PaperTrail::Version.count }.by 1
      expect(controller.send(:origin_user)).to be_nil
    end

    it "redirects back if no origin_user" do
      delete :destroy, params: {group_id: group.id, person_id: people(:bottom_member).id}
      is_expected.to redirect_to(request.env["HTTP_REFERER"])
    end
  end
end
