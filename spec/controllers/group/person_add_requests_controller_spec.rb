# encoding: utf-8

#  Copyright (c) 2012-2015 Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Group::PersonAddRequestsController do

  before { sign_in(user) }
  let(:group) { groups(:top_layer) }
  let(:user) { people(:top_leader) }

  describe "GET index" do

    context "status notification" do

      it "shows nothing if no params passed" do
        get :index, params: { group_id: group.id }

        expect(flash[:notice]).to be_blank
        expect(flash[:alert]).to be_blank
      end

      it "shows nothing if not all params passed" do
        get :index, params: { group_id: group.id, person_id: 42, body_id: 10 }

        expect(flash[:notice]).to be_blank
        expect(flash[:alert]).to be_blank
      end

      it "shows nothing if person_id not in layer" do
        get :index,
            params: {
              group_id: group.id,
              person_id: people(:bottom_member).id,
              body_id: groups(:top_group).id,
              body_type: "Group"
            }

        expect(flash[:notice]).to be_blank
        expect(flash[:alert]).to be_blank
      end

      it "shows approved message if role exists" do
        get :index,
            params: {
              group_id: group.id,
              person_id: people(:top_leader).id,
              body_id: groups(:top_group).id,
              body_type: "Group"
            }

        expect(flash[:notice]).to match(/freigegeben/)
        expect(flash[:alert]).to be_blank
      end

      it "shows rejected message if role does not exist" do
        get :index,
            params: {
              group_id: group.id,
              person_id: people(:top_leader).id,
              body_id: groups(:top_layer).id,
              body_type: "Group"
            }

        expect(flash[:notice]).to be_blank
        expect(flash[:alert]).to match(/abgelehnt/)
      end

      it "assigns current if request exists" do
        request = Person::AddRequest::Group.create!(
          person: people(:top_leader),
          body: groups(:top_layer),
          role_type: Group::TopLayer::TopAdmin.sti_name,
          requester: people(:bottom_member)
        )

        get :index,
            params: {
              group_id: group.id,
              person_id: people(:top_leader).id,
              body_id: groups(:top_layer).id,
              body_type: "Group"
            }

        expect(flash[:notice]).to be_blank
        expect(flash[:alert]).to be_blank

        expect(assigns(:add_requests)).to eq([request])
        expect(assigns(:current_add_request)).to eq(request)
      end
    end
  end

  context "POST activate" do
    let(:other_group) { groups(:bottom_layer_one) }

    it "activates person add requests requirement if user has write permissions" do
      post :activate, params: { group_id: group.id }

      expect(group.reload.require_person_add_requests).to be true
      expect(flash[:notice]).to match(/aktiviert/)
    end

    it "access denied when trying to activate for other group" do
      expect do
        post :activate, params: { group_id: other_group.id }
      end.to raise_error(CanCan::AccessDenied)
    end

  end

  context "DELETE deactivate" do

    before { group.update_attribute(:require_person_add_requests, true) }
    let(:other_group) { groups(:bottom_layer_one) }

    it "deactivates person add requests requirement if user has write permissions" do
      delete :deactivate, params: { group_id: group.id }

      expect(group.reload.require_person_add_requests).to be false
      expect(flash[:notice]).to match(/deaktiviert/)
    end

    it "access denied when trying to deactivate for other group" do
      expect do
        delete :deactivate, params: { group_id: other_group.id }
      end.to raise_error(CanCan::AccessDenied)
    end

  end

end
