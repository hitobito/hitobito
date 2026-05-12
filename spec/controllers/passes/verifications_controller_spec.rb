# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe Passes::VerificationsController do
  let(:person) { people(:top_leader) }
  let(:definition) { Fabricate(:pass_definition, owner: groups(:top_layer)) }

  subject(:dom) { Capybara::Node::Simple.new(response.body) }

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

  describe "views" do
    render_views
    let!(:pass) do
      Fabricate(:pass, person: person, pass_definition: definition,
        state: :eligible, valid_from: 1.month.ago.to_date)
    end

    it "confirms active membership" do
      definition.owner.update!(street: "Muhrgasse", housenumber: "42a", zip_code: "4242", town: "Romyland")

      get :show, params: {verify_token: pass.verify_token}

      expect(dom).to have_selector("#pass-verify header #group-address strong", text: "Top")
      expect(dom).to have_selector("#pass-verify header #group-address p", text: "Muhrgasse 42a4242 Romyland")

      expect(dom).to have_selector("#pass-verify #details #member-name", text: "Top Leader")
      expect(dom).to have_selector("#pass-verify #details .alert-success", text: "Pass ist gültig")
      expect(dom).to have_selector("#pass-verify #details .alert-success span.fa-check")
    end

    it "confirms expired membership" do
      pass.update(state: :ended)
      get :show, params: {verify_token: pass.verify_token}

      expect(dom).to have_selector("#pass-verify #details #member-name", text: "Top Leader")
      expect(dom).to have_selector("#pass-verify #details .alert-warning", text: "Pass ist abgelaufen")
      expect(dom).not_to have_selector("#pass-verify #details .alert-success", text: "Pass ist gültig")
    end

    it "confirms revoked membership" do
      pass.update(state: :revoked)
      get :show, params: {verify_token: pass.verify_token}

      expect(dom).to have_selector("#pass-verify #details #member-name", text: "Top Leader")
      expect(dom).to have_selector("#pass-verify #details .alert-danger", text: "Pass ist ungültig")
      expect(dom).not_to have_selector("#pass-verify #details .alert-success", text: "Pass ist gültig")
    end

    it "confirms unknown pass" do
      get :show, params: {verify_token: "invalid"}
      expect(dom).to have_selector("#pass-verify #details .alert-danger",
        text: "Dieser Pass konnte nicht verifiziert werden.")
      expect(dom).not_to have_selector("#pass-verify #details #member-name", text: "Top Leader")
      expect(dom).not_to have_selector("#pass-verify #details .alert-success", text: "Pass ist gültig")
    end

    describe "logo" do
      def logo_path(image)
        controller.view_context.image_pack_tag(image)[/src="(.*?)"/, 1]
      end

      it "has application logo" do
        src = logo_path(Settings.application.logo.image)
        get :show, params: {verify_token: pass.verify_token}
        expect(dom).to have_css("#logo img[src=\"#{src}\"]")
      end

      it "may be overriden by membership_verify_logo" do
        allow(Settings.application).to receive(:membership_verify_logo).and_return(
          double("logo", {image: "oauth_app.png"})
        )
        get :show, params: {verify_token: pass.verify_token}
        expect(dom).to have_css("#logo img[src=\"#{logo_path("oauth_app.png")}\"]")
      end
    end
  end
end
