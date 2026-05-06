#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Wallets::AppleWallet::WebServiceController do
  let(:person) { people(:top_leader) }
  let(:definition) do
    Fabricate(:pass_definition,
      owner: groups(:top_layer),
      name: "SAC Mitgliedschaft",
      description: "Mitgliedschaftsausweis",
      background_color: "#003366")
  end
  let(:pass) do
    Fabricate(:pass, person: person, pass_definition: definition,
      state: :eligible, valid_from: Date.current)
  end
  let(:installation) do
    Fabricate(:wallets_pass_installation, pass: pass, wallet_type: :apple)
  end
  let(:auth_token) { installation.authentication_token }
  let(:pass_type_id) { "pass.com.example.test" }
  let(:device_id) { "device-abc-123" }
  let(:serial) { Wallets::AppleWallet::PassService.new(installation).serial_number }

  before do
    # NOTE: mock as wallet_identifier is calculated from pass installation via PassService
    allow(Wallets::AppleWallet::PkpassGenerator).to receive(:new)
  end

  describe "POST #register_device" do
    let(:push_token) { SecureRandom.hex(32) }

    it "creates a new device registration and returns 201" do
      request.headers["Authorization"] = "ApplePass #{auth_token}"

      expect {
        post :register_device,
          params: {device_id: device_id, pass_type_id: pass_type_id, serial: serial},
          body: {pushToken: push_token}.to_json,
          as: :json
      }.to change(Wallets::AppleWallet::DeviceRegistration, :count).by(1)

      expect(response).to have_http_status(:created)
    end

    it "returns 200 when device is already registered" do
      Fabricate(:wallets_apple_device_registration,
        pass_installation: installation,
        device_library_identifier: device_id,
        push_token: "old-token")

      request.headers["Authorization"] = "ApplePass #{auth_token}"
      post :register_device,
        params: {device_id: device_id, pass_type_id: pass_type_id, serial: serial},
        body: {pushToken: push_token}.to_json,
        as: :json

      expect(response).to have_http_status(:ok)
    end

    it "updates push_token on re-registration" do
      reg = Fabricate(:wallets_apple_device_registration,
        pass_installation: installation,
        device_library_identifier: device_id,
        push_token: "old-token")

      request.headers["Authorization"] = "ApplePass #{auth_token}"
      post :register_device,
        params: {device_id: device_id, pass_type_id: pass_type_id, serial: serial},
        body: {pushToken: push_token}.to_json,
        as: :json

      expect(reg.reload.push_token).to eq(push_token)
    end

    it "returns 401 without authorization header" do
      post :register_device,
        params: {device_id: device_id, pass_type_id: pass_type_id, serial: serial},
        body: {pushToken: push_token}.to_json,
        as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 with invalid token" do
      request.headers["Authorization"] = "ApplePass invalid-token"
      post :register_device,
        params: {device_id: device_id, pass_type_id: pass_type_id, serial: serial},
        body: {pushToken: push_token}.to_json,
        as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "DELETE #unregister_device" do
    it "deletes the device registration and returns 200" do
      _reg = Fabricate(:wallets_apple_device_registration,
        pass_installation: installation,
        device_library_identifier: device_id)

      request.headers["Authorization"] = "ApplePass #{auth_token}"

      expect {
        delete :unregister_device,
          params: {device_id: device_id, pass_type_id: pass_type_id, serial: serial}
      }.to change(Wallets::AppleWallet::DeviceRegistration, :count).by(-1)

      expect(response).to have_http_status(:ok)
    end

    it "returns 200 even when registration does not exist" do
      request.headers["Authorization"] = "ApplePass #{auth_token}"
      delete :unregister_device,
        params: {device_id: device_id, pass_type_id: pass_type_id, serial: serial}

      expect(response).to have_http_status(:ok)
    end

    it "returns 401 without authorization" do
      delete :unregister_device,
        params: {device_id: device_id, pass_type_id: pass_type_id, serial: serial}

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET #updatable_passes" do
    it "returns serial numbers of updated passes" do
      Fabricate(:wallets_apple_device_registration,
        pass_installation: installation,
        device_library_identifier: device_id)

      get :updatable_passes, params: {device_id: device_id, pass_type_id: pass_type_id}

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["serialNumbers"]).to include(installation.wallet_identifier)
      expect(body["lastUpdated"]).to be_present
    end

    it "filters by passesUpdatedSince" do
      Fabricate(:wallets_apple_device_registration,
        pass_installation: installation,
        device_library_identifier: device_id)

      installation.update_columns(updated_at: 2.days.ago)

      get :updatable_passes,
        params: {device_id: device_id, pass_type_id: pass_type_id,
                 passesUpdatedSince: 1.day.ago.to_i.to_s}

      expect(response).to have_http_status(:no_content)
    end

    it "returns passes updated after passesUpdatedSince" do
      Fabricate(:wallets_apple_device_registration,
        pass_installation: installation,
        device_library_identifier: device_id)

      installation.update_columns(updated_at: 1.hour.ago)

      get :updatable_passes,
        params: {device_id: device_id, pass_type_id: pass_type_id,
                 passesUpdatedSince: 2.hours.ago.to_i.to_s}

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["serialNumbers"]).to include(installation.wallet_identifier)
    end

    it "returns 204 when no passes are updated" do
      get :updatable_passes, params: {device_id: "unknown-device", pass_type_id: pass_type_id}

      expect(response).to have_http_status(:no_content)
    end

    it "does not require authentication" do
      get :updatable_passes, params: {device_id: device_id, pass_type_id: pass_type_id}

      expect(response.status).not_to eq(401)
    end
  end

  describe "GET #send_updated_pass" do
    before do
      allow(Wallets::AppleWallet::Config).to receive(:exist?).and_return(true)
      allow(Wallets::AppleWallet::Config).to receive(:pass_type_identifier).and_return(pass_type_id)
      allow(Wallets::AppleWallet::Config).to receive(:team_identifier).and_return("ABCDE12345")
      allow(Wallets::AppleWallet::Config).to receive(:web_service_url).and_return("https://example.com/wallets/apple")
    end

    it "returns a pkpass file" do
      client = instance_double(Wallets::AppleWallet::PkpassGenerator)
      allow(Wallets::AppleWallet::PkpassGenerator).to receive(:new).and_return(client)
      allow(client).to receive(:create_pass).and_return("binary-pkpass-data")

      request.headers["Authorization"] = "ApplePass #{auth_token}"
      get :send_updated_pass,
        params: {pass_type_id: pass_type_id, serial: serial}

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to eq("application/vnd.apple.pkpass")
      expect(response.body).to eq("binary-pkpass-data")
    end

    it "sends voided pass when installation is revoked" do
      installation.update!(state: :revoked)

      client = instance_double(Wallets::AppleWallet::PkpassGenerator)
      allow(Wallets::AppleWallet::PkpassGenerator).to receive(:new).and_return(client)

      received_pass_data = nil
      allow(client).to receive(:create_pass) { |data|
        received_pass_data = data
        "binary-data"
      }

      request.headers["Authorization"] = "ApplePass #{auth_token}"
      get :send_updated_pass,
        params: {pass_type_id: pass_type_id, serial: serial}

      expect(response).to have_http_status(:ok)
      expect(received_pass_data[:voided]).to eq(true)
    end

    it "sends non-voided pass when installation is active" do
      client = instance_double(Wallets::AppleWallet::PkpassGenerator)
      allow(Wallets::AppleWallet::PkpassGenerator).to receive(:new).and_return(client)

      received_pass_data = nil
      allow(client).to receive(:create_pass) { |data|
        received_pass_data = data
        "binary-data"
      }

      request.headers["Authorization"] = "ApplePass #{auth_token}"
      get :send_updated_pass,
        params: {pass_type_id: pass_type_id, serial: serial}

      expect(response).to have_http_status(:ok)
      expect(received_pass_data[:voided]).to eq(false)
    end

    it "returns 401 without authorization" do
      get :send_updated_pass,
        params: {pass_type_id: pass_type_id, serial: serial}

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST #log_message" do
    it "accepts log messages and returns 200" do
      post :log_message,
        body: {logs: ["Error loading pass", "Network timeout"]}.to_json,
        as: :json

      expect(response).to have_http_status(:ok)
    end

    it "logs messages to Rails logger" do
      allow(Rails.logger).to receive(:info).and_call_original

      post :log_message,
        body: {logs: ["Error loading pass", "Network timeout"]}.to_json,
        as: :json

      expect(Rails.logger).to have_received(:info).with("[AppleWallet] Error loading pass")
      expect(Rails.logger).to have_received(:info).with("[AppleWallet] Network timeout")
    end

    it "returns 200 even with invalid JSON" do
      request.headers["Content-Type"] = "application/json"
      post :log_message, body: "not valid json"

      expect(response).to have_http_status(:ok)
    end

    it "does not require authentication" do
      post :log_message,
        body: {logs: ["test"]}.to_json,
        as: :json

      expect(response.status).not_to eq(401)
    end
  end

  describe "authentication" do
    it "rejects requests without Authorization header" do
      get :send_updated_pass,
        params: {pass_type_id: pass_type_id, serial: serial}

      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects requests with wrong Authorization scheme" do
      request.headers["Authorization"] = "Bearer #{auth_token}"
      get :send_updated_pass,
        params: {pass_type_id: pass_type_id, serial: serial}

      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects requests with non-existent serial" do
      request.headers["Authorization"] = "ApplePass #{auth_token}"
      get :send_updated_pass,
        params: {pass_type_id: pass_type_id, serial: "nonexistent"}

      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects requests with mismatched token" do
      request.headers["Authorization"] = "ApplePass wrong-token"
      get :send_updated_pass,
        params: {pass_type_id: pass_type_id, serial: serial}

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
