#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Wallets::AppleWallet::Config do
  let(:config_data) do
    {
      "apple_wallet" => {
        "pass_type_identifier" => "pass.com.example.membership",
        "team_identifier" => "ABC123DEF4",
        "p12_certificate_path" => "config/apple_wallet.p12",
        "p12_password" => "secret",
        "wwdr_certificate_path" => "config/AppleWWDRCAG4.cer",
        "web_service_url" => "https://app.example.com/wallets/apple",
        "contact_info" => "info@example.com"
      }
    }
  end

  let(:config_path) { Rails.root.join("tmp", "test_apple_wallet.yml") }

  before do
    described_class.instance_variable_set(:@config, nil)
    described_class.remove_instance_variable(:@config) if described_class.instance_variable_defined?(:@config)

    stub_const("Wallets::AppleWallet::Config::FILE_PATH", config_path)
  end

  after do
    FileUtils.rm_f(config_path)
  end

  describe ".exist?" do
    it "returns true when config file is present and valid" do
      File.write(config_path, YAML.dump(config_data))
      expect(described_class.exist?).to be true
    end

    it "returns false when config file is missing" do
      expect(described_class.exist?).to be false
    end

    it "returns false when config file has no apple_wallet key" do
      File.write(config_path, YAML.dump({"other" => {}}))
      expect(described_class.exist?).to be false
    end
  end

  describe "KEYS accessors" do
    before { File.write(config_path, YAML.dump(config_data)) }

    it "returns pass_type_identifier" do
      expect(described_class.pass_type_identifier).to eq("pass.com.example.membership")
    end

    it "returns team_identifier" do
      expect(described_class.team_identifier).to eq("ABC123DEF4")
    end

    it "returns p12_certificate_path" do
      expect(described_class.p12_certificate_path).to eq("config/apple_wallet.p12")
    end

    it "returns p12_password" do
      expect(described_class.p12_password).to eq("secret")
    end

    it "returns wwdr_certificate_path" do
      expect(described_class.wwdr_certificate_path).to eq("config/AppleWWDRCAG4.cer")
    end

    it "returns web_service_url" do
      expect(described_class.web_service_url).to eq("https://app.example.com/wallets/apple")
    end

    it "returns contact_info" do
      expect(described_class.contact_info).to eq("info@example.com")
    end
  end
end
