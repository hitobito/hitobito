#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Wallets::GoogleWallet::Config do
  let(:config_data) do
    {
      "google_wallet" => {
        "issuer_id" => "3388000000022266745",
        "issuer_email" => "wallet@project.iam.gserviceaccount.com"
      }
    }
  end

  let(:service_account_data) do
    {
      "type" => "service_account",
      "project_id" => "test-project",
      "private_key" => OpenSSL::PKey::RSA.generate(2048).to_pem,
      "client_email" => "sa@test-project.iam.gserviceaccount.com"
    }
  end

  let(:config_path) { Rails.root.join("tmp", "test_google_wallet.yml") }
  let(:service_account_path) { Rails.root.join("tmp", "test_service_account.json") }

  before do
    # Reset memoized state between tests (use remove_instance_variable so defined? guard is cleared)
    %i[@config @service_account_json @private_key @client_email @parsed_credentials].each do |ivar|
      described_class.remove_instance_variable(ivar) if described_class.instance_variable_defined?(ivar)
    end

    stub_const("Wallets::GoogleWallet::Config::FILE_PATH", config_path)
    stub_const("Wallets::GoogleWallet::Config::SERVICE_ACCOUNT_PATH", service_account_path)
  end

  after do
    FileUtils.rm_f(config_path)
    FileUtils.rm_f(service_account_path)
  end

  describe ".exist?" do
    it "returns true when config file is present and valid" do
      File.write(config_path, YAML.dump(config_data))
      File.write(service_account_path, JSON.generate(service_account_data))
      expect(described_class.exist?).to be true
    end

    it "returns false when config file is missing" do
      expect(described_class.exist?).to be false
    end

    it "returns false when config file has no google_wallet key" do
      File.write(config_path, YAML.dump({"other" => {}}))
      expect(described_class.exist?).to be false
    end
  end

  describe "KEYS accessors" do
    before { File.write(config_path, YAML.dump(config_data)) }

    it "returns issuer_id" do
      expect(described_class.issuer_id).to eq("3388000000022266745")
    end

    it "returns issuer_email" do
      expect(described_class.issuer_email).to eq("wallet@project.iam.gserviceaccount.com")
    end
  end

  describe ".service_account_json" do
    before do
      File.write(config_path, YAML.dump(config_data))
      File.write(service_account_path, JSON.generate(service_account_data))
    end

    it "reads the service account JSON file" do
      json = described_class.service_account_json
      expect(JSON.parse(json)).to eq(service_account_data)
    end

    it "memoizes the result" do
      first = described_class.service_account_json
      second = described_class.service_account_json
      expect(first).to equal(second)
    end
  end

  describe ".private_key" do
    before do
      File.write(config_path, YAML.dump(config_data))
      File.write(service_account_path, JSON.generate(service_account_data))
    end

    it "extracts private_key from service account JSON" do
      expect(described_class.private_key).to eq(service_account_data["private_key"])
    end
  end

  describe ".client_email" do
    before do
      File.write(config_path, YAML.dump(config_data))
      File.write(service_account_path, JSON.generate(service_account_data))
    end

    it "extracts client_email from service account JSON" do
      expect(described_class.client_email).to eq("sa@test-project.iam.gserviceaccount.com")
    end
  end
end
