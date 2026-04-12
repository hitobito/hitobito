# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe Person::PassesController do
  let(:person) { people(:top_leader) }
  let(:group) { groups(:top_group) }
  let(:definition) { Fabricate(:pass_definition, owner: groups(:top_layer)) }
  let!(:grant) do
    Fabricate(:pass_grant, pass_definition: definition, grantor: groups(:top_group)).tap do |g|
      g.role_types = [Group::TopGroup::Leader.sti_name]
    end
  end

  before { sign_in(person) }

  describe "GET #index" do
    it "lists passes for the person" do
      pass = person.passes.create!(
        pass_definition: definition,
        state: :eligible,
        valid_from: Date.current
      )

      get :index, params: {group_id: group.id, person_id: person.id}

      expect(response).to be_successful
      expect(assigns(:group)).to eq(group)
      expect(assigns(:person)).to eq(person)
      expect(assigns(:passes)).to include(pass)
    end

    it "shows empty state when no passes exist" do
      get :index, params: {group_id: group.id, person_id: person.id}

      expect(response).to be_successful
      expect(assigns(:passes)).to be_empty
    end

    it "raises CanCan::AccessDenied for unauthorized user" do
      sign_in(people(:bottom_member))

      expect {
        get :index, params: {group_id: group.id, person_id: person.id}
      }.to raise_error(CanCan::AccessDenied)
    end
  end

  describe "GET #show" do
    let!(:pass) do
      person.passes.create!(pass_definition: definition,
        state: :eligible, valid_from: Date.current)
    end

    context "format.html" do
      it "renders the show view" do
        get :show, params: {group_id: group.id, person_id: person.id, id: definition.id}

        expect(response).to be_successful
        expect(assigns(:group)).to eq(group)
        expect(assigns(:person)).to eq(person)
        expect(assigns(:pass)).to eq(pass)
      end

      it "returns 404 when no passes exists" do
        pass.delete

        expect {
          get :show, params: {group_id: group.id, person_id: person.id, id: definition.id}
        }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "raises CanCan::AccessDenied for unauthorized user" do
        sign_in(people(:bottom_member))

        expect {
          get :show, params: {group_id: group.id, person_id: person.id, id: definition.id}
        }.to raise_error(CanCan::AccessDenied)
      end
    end

    context "GET #google_wallet" do
      let(:save_url) { "https://pay.google.com/gp/v/save/jwt-token" }
      let(:google_service) { instance_double(Wallets::GoogleWallet::PassService, save_url: save_url) }
      let(:synchronizer) { instance_double(Wallets::PassSynchronizer) }

      before do
        allow(Wallets::GoogleWallet::PassService).to receive(:new).and_return(google_service)
        allow(Wallets::PassSynchronizer).to receive(:new).and_return(synchronizer)
        allow(synchronizer).to receive(:compute_validity!)
      end

      it "creates pass installation and redirects to Google Wallet" do
        expect(synchronizer).to receive(:compute_validity!)

        expect {
          get :google_wallet, params: {group_id: group.id, person_id: person.id, id: definition.id}
        }.to change(Wallets::PassInstallation, :count).by(1)

        expect(response).to redirect_to(save_url)
        installation = Wallets::PassInstallation.last
        expect(installation.wallet_type).to eq("google")
      end

      it "returns 404 when no passes exists" do
        pass.delete

        expect {
          get :google_wallet, params: {group_id: group.id, person_id: person.id, id: definition.id}
        }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "passes the installation to GoogleWallet::PassService" do
        expect(Wallets::GoogleWallet::PassService).to receive(:new)
          .with(kind_of(Wallets::PassInstallation))
          .and_return(google_service)

        get :google_wallet, params: {group_id: group.id, person_id: person.id, id: definition.id}
      end

      it "reuses existing passes and installation" do
        pass.pass_installations.create!(
          wallet_type: :google,
          locale: person.language
        )

        expect {
          get :google_wallet, params: {group_id: group.id, person_id: person.id, id: definition.id}
        }.not_to change(Wallets::PassInstallation, :count)

        expect(response).to redirect_to(save_url)
      end

      it "redirects back with alert on error" do
        allow(google_service).to receive(:save_url).and_raise(StandardError.new("API error"))

        get :google_wallet, params: {group_id: group.id, person_id: person.id, id: definition.id}

        expect(response).to redirect_to(group_person_path(group, person))
        expect(flash[:alert]).to eq(I18n.t("wallets.google.save_failed"))
      end
    end

    context "format.pkpass" do
      let(:pkpass_data) { "fake-pkpass-binary-data" }
      let(:apple_service) { instance_double(Wallets::AppleWallet::PassService, generate_pass: pkpass_data) }
      let(:synchronizer) { instance_double(Wallets::PassSynchronizer) }

      before do
        stub_const("Wallets::AppleWallet::PassService", Class.new)
        allow(Wallets::AppleWallet::PassService).to receive(:new).and_return(apple_service)
        allow(Wallets::PassSynchronizer).to receive(:new).and_return(synchronizer)
        allow(synchronizer).to receive(:compute_validity!)
      end

      it "creates pass installation and sends pkpass file" do
        expect(synchronizer).to receive(:compute_validity!)

        expect {
          get :show, params: {group_id: group.id, person_id: person.id, id: definition.id}, format: :pkpass
        }.to change(Wallets::PassInstallation, :count).by(1)

        expect(response).to be_successful
        expect(response.media_type).to eq("application/vnd.apple.pkpass")
        expect(response.body).to eq(pkpass_data)

        installation = Wallets::PassInstallation.last
        expect(installation.wallet_type).to eq("apple")
      end

      it "redirects back with alert on error" do
        allow(apple_service).to receive(:generate_pass).and_raise(StandardError.new("signing error"))

        get :show, params: {group_id: group.id, person_id: person.id, id: definition.id}, format: :pkpass

        expect(response).to redirect_to(group_person_path(group, person))
        expect(flash[:alert]).to eq(I18n.t("wallets.apple.generation_failed"))
      end
    end

    context "format.pdf" do
      let(:pdf_data) { "%PDF-fake" }
      let(:pdf_double) { instance_double("PdfExport", render: pdf_data, filename: "pass.pdf") }
      let(:pdf_class) { Class.new }
      let(:template) {
        Passes::TemplateRegistry::Template.new(pdf_class: pdf_class, pass_view_partial: "default",
          wallet_data_provider: Passes::WalletDataProvider)
      }

      before do
        allow(pdf_class).to receive(:new).and_return(pdf_double)
        allow(Passes::TemplateRegistry).to receive(:fetch).with("default").and_return(template)
      end

      it "renders PDF" do
        get :show, params: {group_id: group.id, person_id: person.id, id: definition.id}, format: :pdf

        expect(response).to be_successful
        expect(response.media_type).to eq("application/pdf")
        expect(response.body).to eq(pdf_data)
      end
    end
  end
end
