#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Devise::SessionsController do
  let(:bottom_group) { groups(:bottom_group_one_one) }
  let(:role) { Fabricate("Group::BottomGroup::Member", group: bottom_group) }
  let(:person) do
    role.person.update_attribute(:password, "password")
    role.person.reload
  end

  context "person has single role" do
    subject { person.roles.first }

    its(:type) { is_expected.to eq "Group::BottomGroup::Member" }
    specify "person has only single role" do
      expect(person.roles.size).to eq 1
    end
  end

  context "#create" do
    before { request.env["devise.mapping"] = Devise.mappings[:person] }

    context ".html" do
      it "sets flash for invalid login data" do
        post :create, params: {person: {email: person.email, password: "foobar"}}
        expect(flash[:alert]).to eq "Ungültige Anmeldedaten."
        expect(controller.send(:current_person)).not_to be_present
      end

      it "logs in person even when they have no login permission" do
        post :create, params: {person: {email: person.email, password: "password"}}
        expect(flash[:alert]).not_to be_present
        expect(controller.send(:current_person)).to be_present
        expect(controller.send(:current_person).authentication_token).to be_blank
      end
    end

    context ".json" do
      render_views

      it "responds with unauthorized for wrong password" do
        post :create, params: {person: {email: person.email, password: "foobar"}}, format: :json
        expect(response.status).to be(401)
        expect(person.reload.authentication_token).to be_blank
      end

      it "responds with user and new token" do
        post :create, params: {person: {email: person.email, password: "password"}}, format: :json
        expect(response.body).to match(/^\{.*"authentication_token":".+"/)
        expect(assigns(:person).authentication_token).to be_present
      end

      it "responds with user and existing token" do
        person.generate_authentication_token!
        post :create, params: {person: {email: person.email, password: "password"}}, format: :json
        expect(response.body).to match(/^\{.*"authentication_token":"#{person.authentication_token}"/)
        expect(assigns(:person).authentication_token).to eq(person.authentication_token)
      end
    end
  end
end
