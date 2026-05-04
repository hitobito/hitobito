# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe Passes::VerificationsController do
  let(:person) { people(:top_leader) }
  let(:definition) { Fabricate(:pass_definition, owner: groups(:top_layer)) }

  describe "GET #show" do
    context "with a valid (active) pass" do
      let!(:pass) do
        Fabricate(:pass, person: person, pass_definition: definition,
          state: :eligible, valid_from: 1.month.ago.to_date)
      end

      it "responds with 200" do
        get :show, params: {verify_token: pass.verify_token}
        expect(response).to be_successful
      end

      it "assigns :valid state" do
        get :show, params: {verify_token: pass.verify_token}
        expect(assigns(:state)).to eq(:valid)
      end

      it "assigns pass, person, definition, template, group" do
        get :show, params: {verify_token: pass.verify_token}
        expect(assigns(:pass)).to eq(pass)
        expect(assigns(:person)).to eq(person)
        expect(assigns(:definition)).to eq(definition)
        expect(assigns(:template)).to be_present
        expect(assigns(:group)).to be_present
      end

      it "does not require authentication" do
        get :show, params: {verify_token: pass.verify_token}
        expect(response).not_to redirect_to(new_person_session_path)
      end
    end

    context "with an expired pass" do
      let!(:pass) do
        Fabricate(:pass, person: person, pass_definition: definition,
          valid_from: 1.year.ago.to_date).tap { |p| p.update_column(:state, "ended") }
      end

      it "assigns :expired state" do
        get :show, params: {verify_token: pass.verify_token}
        expect(assigns(:state)).to eq(:expired)
      end
    end

    context "with an unknown verify_token" do
      it "responds with 200" do
        get :show, params: {verify_token: "unknown_token"}
        expect(response).to be_successful
      end

      it "assigns :invalid state" do
        get :show, params: {verify_token: "unknown_token"}
        expect(assigns(:state)).to eq(:invalid)
      end
    end
  end
end
