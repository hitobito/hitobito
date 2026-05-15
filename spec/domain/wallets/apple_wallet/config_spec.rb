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
        "certificate_path" => "config/apple-wallet-pass.cer",
        "key_path" => "config/apple-wallet-pass.key",
        "key_password" => "",
        "wwdr_certificate_path" => "config/AppleWWDRCAG4.cer",
        "web_service_url" => "https://app.example.com/wallets/apple"
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

    it "returns certificate_path" do
      expect(described_class.certificate_path).to eq("config/apple-wallet-pass.cer")
    end

    it "returns key_path" do
      expect(described_class.key_path).to eq("config/apple-wallet-pass.key")
    end

    it "returns key_password" do
      expect(described_class.key_password).to eq("")
    end

    it "returns wwdr_certificate_path" do
      expect(described_class.wwdr_certificate_path).to eq("config/AppleWWDRCAG4.cer")
    end

    it "returns web_service_url" do
      expect(described_class.web_service_url).to eq("https://app.example.com/wallets/apple")
    end
  end

  describe "certificate helper methods" do
    let(:tmp_dir) { Rails.root.join("tmp", "apple_wallet_cert_test") }
    let(:cert_path) { tmp_dir.join("test.cer").to_s }
    let(:key_path) { tmp_dir.join("test.key").to_s }
    let(:wwdr_path) { tmp_dir.join("wwdr.cer").to_s }

    let(:test_key) { OpenSSL::PKey::RSA.new(2048) }
    let(:test_cert) do
      cert = OpenSSL::X509::Certificate.new
      cert.subject = OpenSSL::X509::Name.new([["CN", "Test"]])
      cert.issuer = cert.subject
      cert.not_before = Time.current
      cert.not_after = Time.current + 3600
      cert.public_key = test_key.public_key
      cert.serial = 1
      cert.sign(test_key, OpenSSL::Digest.new("SHA256"))
      cert
    end

    let(:cert_config_data) do
      {
        "apple_wallet" => {
          "pass_type_identifier" => "pass.com.example.test",
          "team_identifier" => "ABC123",
          "certificate_path" => cert_path,
          "key_path" => key_path,
          "key_password" => "",
          "wwdr_certificate_path" => wwdr_path,
          "web_service_url" => "https://example.com"
        }
      }
    end

    before do
      FileUtils.mkdir_p(tmp_dir)
      File.write(cert_path, test_cert.to_pem)
      File.write(key_path, test_key.to_pem)
      File.binwrite(wwdr_path, test_cert.to_der)
      File.write(config_path, YAML.dump(cert_config_data))

      # Clear memoization
      described_class.instance_variable_set(:@certificate, nil)
      described_class.instance_variable_set(:@key, nil)
      described_class.instance_variable_set(:@wwdr_certificate, nil)
      if described_class.instance_variable_defined?(:@certificate)
        described_class.remove_instance_variable(:@certificate)
      end
      described_class.remove_instance_variable(:@key) if described_class.instance_variable_defined?(:@key)
      if described_class.instance_variable_defined?(:@wwdr_certificate)
        described_class.remove_instance_variable(:@wwdr_certificate)
      end
    end

    after do
      FileUtils.rm_rf(tmp_dir)
    end

    describe ".certificate" do
      it "loads and returns the PassKit certificate" do
        cert = described_class.certificate
        expect(cert).to be_a(OpenSSL::X509::Certificate)
        expect(cert.subject.to_s).to include("CN=Test")
      end

      it "raises helpful error when file not found" do
        File.delete(cert_path)
        expect {
          described_class.certificate
        }.to raise_error(/Failed to load PassKit certificate.*#{Regexp.escape(cert_path)}/)
      end

      it "caches the certificate" do
        cert1 = described_class.certificate
        cert2 = described_class.certificate
        expect(cert1).to equal(cert2)
      end
    end

    describe ".key" do
      it "loads and returns the private key" do
        key = described_class.key
        expect(key).to be_a(OpenSSL::PKey::RSA)
      end

      it "raises helpful error when file not found" do
        File.delete(key_path)
        expect {
          described_class.key
        }.to raise_error(/Failed to load private key.*#{Regexp.escape(key_path)}/)
      end

      it "caches the key" do
        key1 = described_class.key
        key2 = described_class.key
        expect(key1).to equal(key2)
      end
    end

    describe ".wwdr_certificate" do
      it "loads and returns the WWDR certificate" do
        wwdr = described_class.wwdr_certificate
        expect(wwdr).to be_a(OpenSSL::X509::Certificate)
      end

      it "raises helpful error when file not found" do
        File.delete(wwdr_path)
        expect {
          described_class.wwdr_certificate
        }.to raise_error(/Failed to load WWDR certificate.*#{Regexp.escape(wwdr_path)}/)
      end

      it "caches the certificate" do
        wwdr1 = described_class.wwdr_certificate
        wwdr2 = described_class.wwdr_certificate
        expect(wwdr1).to equal(wwdr2)
      end
    end
  end
end
