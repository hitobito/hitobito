#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe People::PassesController do
  let(:person) { people(:top_leader) }
  let(:group) { groups(:top_group) }
  let(:definition) { Fabricate(:pass_definition, owner: groups(:top_layer)) }
  let(:grant) do
    Fabricate(:pass_grant, pass_definition: definition, grantor: groups(:top_group)).tap do |g|
      g.role_types = [Group::TopGroup::Leader.sti_name]
    end
  end

  before { sign_in(person) }

  describe "GET #index" do
    it "lists pass memberships for the person" do
      grant
      membership = person.pass_memberships.create!(
        pass_definition: definition,
        state: :eligible,
        valid_from: Date.current
      )

      get :index, params: {group_id: group.id, person_id: person.id}

      expect(response).to be_successful
      expect(assigns(:pass_memberships)).to include(membership)
      expect(assigns(:group)).to eq(group)
      expect(assigns(:person)).to eq(person)
    end

    it "shows empty state when no memberships exist" do
      get :index, params: {group_id: group.id, person_id: person.id}

      expect(response).to be_successful
      expect(assigns(:pass_memberships)).to be_empty
    end

    it "raises CanCan::AccessDenied for unauthorized user" do
      sign_in(people(:bottom_member))

      expect {
        get :index, params: {group_id: group.id, person_id: person.id}
      }.to raise_error(CanCan::AccessDenied)
    end
  end

  describe "GET #show" do
    context "format.html" do
      it "renders the show view" do
        get :show, params: {group_id: group.id, person_id: person.id, id: definition.id}

        expect(response).to be_successful
        expect(assigns(:pass)).to be_a(Pass)
        expect(assigns(:pass).definition).to eq(definition)
        expect(assigns(:group)).to eq(group)
        expect(assigns(:person)).to eq(person)
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
        expect {
          get :google_wallet, params: {group_id: group.id, person_id: person.id, id: definition.id}
        }.to change(Wallets::PassInstallation, :count).by(1)
          .and change(PassMembership, :count).by(1)

        expect(response).to redirect_to(save_url)
        installation = Wallets::PassInstallation.last
        expect(installation.wallet_type).to eq("google")
        expect(installation.wallet_identifier).to be_present
      end

      it "reuses existing pass membership and installation" do
        membership = person.pass_memberships.create!(
          pass_definition: definition,
          state: :eligible,
          valid_from: Date.current
        )
        membership.pass_installations.create!(
          wallet_type: :google,
          wallet_identifier: SecureRandom.uuid
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
        expect {
          get :show, params: {group_id: group.id, person_id: person.id, id: definition.id}, format: :pkpass
        }.to change(Wallets::PassInstallation, :count).by(1)
          .and change(PassMembership, :count).by(1)

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
      let(:pdf_double) { instance_double("PdfExport", render: "%PDF-fake", filename: "pass.pdf") }
      let(:pdf_class) { Class.new }

      before do
        stub_const("Export::Pdf::Passes::Default", pdf_class)
        allow(pdf_class).to receive(:new).and_return(pdf_double)
      end

      it "renders PDF" do
        get :show, params: {group_id: group.id, person_id: person.id, id: definition.id}, format: :pdf

        expect(response).to be_successful
        expect(response.media_type).to eq("application/pdf")
      end
    end
  end

  describe "#find_or_create_pass_installation" do
    it "sets validity from Pass PORO when creating membership" do
      allow_any_instance_of(Pass).to receive(:eligible?).and_return(true)
      allow_any_instance_of(Pass).to receive(:valid_from).and_return(Date.new(2025, 1, 1))
      allow_any_instance_of(Pass).to receive(:valid_until).and_return(Date.new(2025, 12, 31))

      save_url = "https://pay.google.com/gp/v/save/test"
      google_service = instance_double(Wallets::GoogleWallet::PassService, save_url: save_url)
      allow(Wallets::GoogleWallet::PassService).to receive(:new).and_return(google_service)
      synchronizer = instance_double(Wallets::PassSynchronizer)
      allow(Wallets::PassSynchronizer).to receive(:new).and_return(synchronizer)
      allow(synchronizer).to receive(:compute_validity!)

      get :google_wallet, params: {group_id: group.id, person_id: person.id, id: definition.id}

      membership = person.pass_memberships.find_by(pass_definition: definition)
      expect(membership.state).to eq("eligible")
      expect(membership.valid_from).to eq(Date.new(2025, 1, 1))
      expect(membership.valid_until).to eq(Date.new(2025, 12, 31))
    end
  end
end
