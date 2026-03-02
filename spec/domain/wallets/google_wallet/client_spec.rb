#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Wallets::GoogleWallet::Client do
  let(:rsa_key) { OpenSSL::PKey::RSA.generate(2048) }

  let(:config_values) do
    {
      "issuer_id" => "3388000000022266745",
      "issuer_email" => "wallet@project.iam.gserviceaccount.com",
      "service_account_json_path" => "/tmp/sa.json"
    }
  end

  let(:service_account_json) do
    JSON.generate(
      "type" => "service_account",
      "private_key" => rsa_key.to_pem,
      "client_email" => "sa@project.iam.gserviceaccount.com"
    )
  end

  let(:base_url) { described_class::BASE_URL }
  let(:token) { "test-access-token-#{SecureRandom.hex(8)}" }

  before do
    allow(Wallets::GoogleWallet::Config).to receive(:exist?).and_return(true)
    allow(Wallets::GoogleWallet::Config).to receive(:issuer_id).and_return(config_values["issuer_id"])
    allow(Wallets::GoogleWallet::Config).to receive(:issuer_email).and_return(config_values["issuer_email"])
    allow(Wallets::GoogleWallet::Config).to receive(:service_account_json).and_return(service_account_json)
    allow(Wallets::GoogleWallet::Config).to receive(:private_key).and_return(rsa_key.to_pem)
    allow(Wallets::GoogleWallet::Config).to receive(:client_email).and_return("sa@project.iam.gserviceaccount.com")

    # Stub OAuth2 token exchange
    authorizer = double("authorizer",
      access_token: token,
      expires_in: 3600)
    allow(authorizer).to receive(:fetch_access_token!)
    allow(Google::Auth::ServiceAccountCredentials).to receive(:make_creds).and_return(authorizer)
  end

  subject(:client) { described_class.new }

  describe "#initialize" do
    it "raises when config file is missing" do
      allow(Wallets::GoogleWallet::Config).to receive(:exist?).and_return(false)
      expect { described_class.new }.to raise_error(/not found/)
    end
  end

  describe "#create_class" do
    let(:payload) { {id: "issuer.class_id", classTemplateInfo: {}} }
    let(:response_body) { {id: "issuer.class_id"}.to_json }

    it "sends POST to genericClass endpoint" do
      stub = stub_request(:post, "#{base_url}/genericClass")
        .with(headers: {"Authorization" => "Bearer #{token}"})
        .to_return(status: 200, body: response_body)

      result = client.create_class(payload)
      expect(stub).to have_been_requested
      expect(result[:id]).to eq("issuer.class_id")
    end

    it "returns existing class on 409 Conflict" do
      stub_request(:post, "#{base_url}/genericClass")
        .to_return(status: 409, body: "")
      get_stub = stub_request(:get, "#{base_url}/genericClass/issuer.class_id")
        .to_return(status: 200, body: response_body)

      result = client.create_class(payload)
      expect(get_stub).to have_been_requested
      expect(result[:id]).to eq("issuer.class_id")
    end

    it "supports event_ticket type" do
      stub = stub_request(:post, "#{base_url}/eventTicketClass")
        .to_return(status: 200, body: response_body)

      client.create_class(payload, type: :event_ticket)
      expect(stub).to have_been_requested
    end
  end

  describe "#create_or_update_object" do
    let(:payload) { {id: "issuer.object_id", classId: "issuer.class_id"} }
    let(:response_body) { {id: "issuer.object_id"}.to_json }

    it "sends POST to genericObject endpoint" do
      stub = stub_request(:post, "#{base_url}/genericObject")
        .to_return(status: 200, body: response_body)

      result = client.create_or_update_object(payload)
      expect(stub).to have_been_requested
      expect(result[:id]).to eq("issuer.object_id")
    end

    it "updates via PUT on 409 Conflict" do
      stub_request(:post, "#{base_url}/genericObject")
        .to_return(status: 409, body: "")
      put_stub = stub_request(:put, "#{base_url}/genericObject/issuer.object_id")
        .to_return(status: 200, body: response_body)

      result = client.create_or_update_object(payload)
      expect(put_stub).to have_been_requested
      expect(result[:id]).to eq("issuer.object_id")
    end

    it "supports event_ticket type" do
      stub = stub_request(:post, "#{base_url}/eventTicketObject")
        .to_return(status: 200, body: response_body)

      client.create_or_update_object(payload, type: :event_ticket)
      expect(stub).to have_been_requested
    end
  end

  describe "#get_object" do
    let(:response_body) { {id: "issuer.object_id", state: "ACTIVE"}.to_json }

    it "sends GET to genericObject endpoint" do
      stub = stub_request(:get, "#{base_url}/genericObject/issuer.object_id")
        .to_return(status: 200, body: response_body)

      result = client.get_object("issuer.object_id")
      expect(stub).to have_been_requested
      expect(result[:state]).to eq("ACTIVE")
    end

    it "supports event_ticket type" do
      stub = stub_request(:get, "#{base_url}/eventTicketObject/issuer.object_id")
        .to_return(status: 200, body: response_body)

      client.get_object("issuer.object_id", type: :event_ticket)
      expect(stub).to have_been_requested
    end
  end

  describe "#generate_save_url" do
    it "returns a save-to-wallet URL with JWT" do
      url = client.generate_save_url("issuer.object_id")
      expect(url).to start_with("https://pay.google.com/gp/v/save/")
    end

    it "encodes a valid JWT with correct claims" do
      url = client.generate_save_url("issuer.object_id")
      jwt_token = url.split("/").last

      decoded = JWT.decode(jwt_token, rsa_key.public_key, true, algorithm: "RS256")
      claims = decoded.first

      expect(claims["iss"]).to eq("wallet@project.iam.gserviceaccount.com")
      expect(claims["aud"]).to eq("google")
      expect(claims["typ"]).to eq("savetowallet")
      expect(claims["payload"]["genericObjects"]).to eq([{"id" => "issuer.object_id"}])
    end

    it "uses eventTicketObjects key for event_ticket type" do
      url = client.generate_save_url("issuer.object_id", type: :event_ticket)
      jwt_token = url.split("/").last

      decoded = JWT.decode(jwt_token, rsa_key.public_key, true, algorithm: "RS256")
      claims = decoded.first

      expect(claims["payload"]["eventTicketObjects"]).to eq([{"id" => "issuer.object_id"}])
    end
  end

  describe "token management" do
    it "renews expired token" do
      # First request — token fetched
      stub_request(:get, "#{base_url}/genericObject/test_id")
        .to_return(status: 200, body: {id: "test_id"}.to_json)

      client.get_object("test_id")

      # Expire the token
      client.instance_variable_set(:@token_expires_at, 1.minute.ago)

      new_authorizer = double("authorizer",
        access_token: "renewed-token",
        expires_in: 3600)
      allow(new_authorizer).to receive(:fetch_access_token!)
      allow(Google::Auth::ServiceAccountCredentials).to receive(:make_creds).and_return(new_authorizer)

      # Force new connection to use renewed token
      client.instance_variable_set(:@connection, nil)
      stub_request(:get, "#{base_url}/genericObject/test_id")
        .with(headers: {"Authorization" => "Bearer renewed-token"})
        .to_return(status: 200, body: {id: "test_id"}.to_json)

      client.get_object("test_id")
    end
  end

  describe "error handling" do
    it "re-raises BadRequestError with extracted message" do
      error_body = {error: {message: "Invalid field value"}}.to_json
      stub_request(:post, "#{base_url}/genericObject")
        .to_return(status: 400, body: error_body)

      expect {
        client.create_or_update_object({id: "bad"})
      }.to raise_error(Faraday::BadRequestError, "Invalid field value")
    end

    it "handles non-JSON error bodies gracefully" do
      stub_request(:post, "#{base_url}/genericObject")
        .to_return(status: 400, body: "plain text error")

      expect {
        client.create_or_update_object({id: "bad"})
      }.to raise_error(Faraday::BadRequestError)
    end
  end
end
