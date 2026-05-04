# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe People::Membership::VerifyController do
  let(:person) { people(:top_leader) }
  let(:definition) { pass_definitions(:top_layer_pass) }
  let!(:pass) do
    Fabricate(:pass, person: person, pass_definition: definition,
      state: :eligible, valid_from: Date.current)
  end

  describe "GET #show" do
    context "with a configured legacy_verify_pass_definition_key" do
      before do
        allow(Settings.passes).to receive(:legacy_verify_pass_definition_key)
          .and_return(definition.template_key)
      end

      it "redirects with 302 to the new pass verify path" do
        get :show, params: {verify_token: person.membership_verify_token}

        expect(response).to redirect_to(pass_verify_path(pass.verify_token))
        expect(response.status).to eq(302)
      end

      it "redirects to not-found when person is unknown" do
        get :show, params: {verify_token: "unknown_token"}

        expect(response).to redirect_to(pass_verify_path("not-found"))
      end

      it "redirects to not-found when pass does not exist for the person" do
        pass.delete

        get :show, params: {verify_token: person.membership_verify_token}

        expect(response).to redirect_to(pass_verify_path("not-found"))
      end
    end

    context "without a configured legacy_verify_pass_definition_key" do
      before do
        allow(Settings.passes).to receive(:legacy_verify_pass_definition_key).and_return(nil)
      end

      it "redirects to not-found" do
        get :show, params: {verify_token: person.membership_verify_token}

        expect(response).to redirect_to(pass_verify_path("not-found"))
      end
    end

    context "with a legacy_verify_pass_definition_key that matches no PassDefinition" do
      before do
        allow(Settings.passes).to receive(:legacy_verify_pass_definition_key)
          .and_return("nonexistent_key")
      end

      it "redirects to not-found" do
        get :show, params: {verify_token: person.membership_verify_token}

        expect(response).to redirect_to(pass_verify_path("not-found"))
      end
    end
  end
end
