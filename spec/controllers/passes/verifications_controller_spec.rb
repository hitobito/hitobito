#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Passes::VerificationsController do
  render_views

  let(:person) { people(:top_leader) }
  let(:group) { groups(:top_layer) }
  let(:definition) { Fabricate(:pass_definition, owner: group) }
  let(:grant) do
    Fabricate(:pass_grant, pass_definition: definition, grantor: groups(:top_group)).tap do |g|
      g.role_types = [Group::TopGroup::Leader.sti_name]
    end
  end
  let(:verify_token) { person.membership_verify_token }

  before do
    grant # ensure grant is created
  end

  describe "GET #show" do
    context "with valid pass" do
      it "is publicly accessible without login" do
        get :show, params: {pass_id: definition.id, verify_token: verify_token}
        expect(response).to have_http_status(:ok)
      end

      it "assigns :valid state" do
        get :show, params: {pass_id: definition.id, verify_token: verify_token}
        expect(assigns(:state)).to eq(:valid)
      end

      it "assigns the person" do
        get :show, params: {pass_id: definition.id, verify_token: verify_token}
        expect(assigns(:person)).to eq(person)
      end

      it "assigns the pass definition" do
        get :show, params: {pass_id: definition.id, verify_token: verify_token}
        expect(assigns(:pass_definition)).to eq(definition)
      end

      it "assigns a Pass PORO" do
        get :show, params: {pass_id: definition.id, verify_token: verify_token}
        expect(assigns(:pass)).to be_a(Pass)
      end

      it "renders without application layout" do
        get :show, params: {pass_id: definition.id, verify_token: verify_token}
        expect(response).to render_template(layout: false)
      end

      it "renders the show template" do
        get :show, params: {pass_id: definition.id, verify_token: verify_token}
        expect(response).to render_template(:show)
      end

      it "contains the valid status text" do
        get :show, params: {pass_id: definition.id, verify_token: verify_token}
        expect(response.body).to include(I18n.t("passes.verifications.status.valid"))
      end

      it "contains the person name" do
        get :show, params: {pass_id: definition.id, verify_token: verify_token}
        expect(response.body).to include(person.full_name)
      end
    end

    context "with invalid token" do
      it "assigns :invalid state" do
        get :show, params: {pass_id: definition.id, verify_token: "nonexistent-token"}
        expect(assigns(:state)).to eq(:invalid)
      end

      it "returns 200 (renders the invalid state page)" do
        get :show, params: {pass_id: definition.id, verify_token: "nonexistent-token"}
        expect(response).to have_http_status(:ok)
      end

      it "contains the invalid status text" do
        get :show, params: {pass_id: definition.id, verify_token: "nonexistent-token"}
        expect(response.body).to include(I18n.t("passes.verifications.status.invalid"))
      end

      it "does not assign a person" do
        get :show, params: {pass_id: definition.id, verify_token: "nonexistent-token"}
        expect(assigns(:person)).to be_nil
      end
    end

    context "with invalid pass definition" do
      it "assigns :invalid state" do
        get :show, params: {pass_id: 0, verify_token: verify_token}
        expect(assigns(:state)).to eq(:invalid)
      end

      it "does not assign a pass" do
        get :show, params: {pass_id: 0, verify_token: verify_token}
        expect(assigns(:pass)).to be_nil
      end
    end

    context "with expired pass" do
      before do
        # Remove the active role and create an ended one
        person.roles.destroy_all
        Fabricate(
          Group::TopGroup::Leader.name.to_sym,
          person: person,
          group: groups(:top_group),
          start_on: 1.year.ago,
          end_on: 1.month.ago
        )
      end

      it "assigns :expired state" do
        get :show, params: {pass_id: definition.id, verify_token: verify_token}
        expect(assigns(:state)).to eq(:expired)
      end

      it "contains the expired status text" do
        get :show, params: {pass_id: definition.id, verify_token: verify_token}
        expect(response.body).to include(I18n.t("passes.verifications.status.expired"))
      end
    end

    context "with ineligible person (no matching roles)" do
      before do
        # Remove all roles so person is neither eligible nor ended
        person.roles.destroy_all
      end

      it "assigns :invalid state" do
        get :show, params: {pass_id: definition.id, verify_token: verify_token}
        expect(assigns(:state)).to eq(:invalid)
      end
    end
  end
end
