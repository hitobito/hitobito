#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"
require "zip"

describe Wallets::AppleWallet::PkpassGenerator do
  let(:tmp_dir) { Rails.root.join("tmp", "apple_wallet_test") }
  let(:p12_path) { tmp_dir.join("test.p12").to_s }
  let(:wwdr_path) { tmp_dir.join("wwdr.cer").to_s }
  let(:config_path) { tmp_dir.join("apple_wallet.yml") }

  # Generate self-signed test certificates
  let(:ca_key) { OpenSSL::PKey::RSA.new(2048) }
  let(:ca_cert) do
    cert = OpenSSL::X509::Certificate.new
    cert.version = 2
    cert.serial = 1
    cert.subject = OpenSSL::X509::Name.parse("/CN=Test WWDR CA")
    cert.issuer = cert.subject
    cert.public_key = ca_key.public_key
    cert.not_before = Time.current - 3600
    cert.not_after = Time.current + 3600
    cert.sign(ca_key, OpenSSL::Digest.new("SHA256"))
    cert
  end

  let(:pass_key) { OpenSSL::PKey::RSA.new(2048) }
  let(:pass_cert) do
    cert = OpenSSL::X509::Certificate.new
    cert.version = 2
    cert.serial = 2
    cert.subject = OpenSSL::X509::Name.parse("/CN=Test Pass Certificate")
    cert.issuer = ca_cert.subject
    cert.public_key = pass_key.public_key
    cert.not_before = Time.current - 3600
    cert.not_after = Time.current + 3600
    cert.sign(ca_key, OpenSSL::Digest.new("SHA256"))
    cert
  end

  let(:p12_password) { "test_password" }
  let(:p12) { OpenSSL::PKCS12.create(p12_password, "pass", pass_key, pass_cert) }

  let(:pass_json) do
    {
      formatVersion: 1,
      passTypeIdentifier: "pass.com.example.membership",
      serialNumber: "123456",
      teamIdentifier: "ABC123DEF4",
      organizationName: "Test Org",
      description: "Test Pass"
    }
  end

  let(:logo_data) { ("\x89PNG\r\n\x1A\n".b + ("\x00" * 16).b) }

  before do
    FileUtils.mkdir_p(tmp_dir)

    File.binwrite(p12_path, p12.to_der)
    File.binwrite(wwdr_path, ca_cert.to_der)
    File.write(config_path, YAML.dump(
      "apple_wallet" => {
        "pass_type_identifier" => "pass.com.example.membership",
        "team_identifier" => "ABC123DEF4",
        "p12_certificate_path" => p12_path,
        "p12_password" => p12_password,
        "wwdr_certificate_path" => wwdr_path,
        "web_service_url" => "https://app.example.com/wallets/apple",
        "contact_info" => "info@example.com"
      }
    ))

    # Reset config memoization
    Wallets::AppleWallet::Config.instance_variable_set(:@config, nil)
    Wallets::AppleWallet::Config.remove_instance_variable(:@config) if
      Wallets::AppleWallet::Config.instance_variable_defined?(:@config)

    stub_const("Wallets::AppleWallet::Config::FILE_PATH", config_path)
  end

  after do
    FileUtils.rm_rf(tmp_dir)
  end

  describe "#create_pass" do
    subject(:pkpass_data) { described_class.new.create_pass(pass_json, images) }

    let(:images) { {"logo.png" => logo_data} }

    it "returns binary data" do
      expect(pkpass_data).to be_a(String)
      expect(pkpass_data.encoding).to eq(Encoding::ASCII_8BIT)
    end

    it "returns a valid ZIP file" do
      entries = zip_entries(pkpass_data)
      expect(entries).to include("pass.json", "manifest.json", "signature")
    end

    it "includes pass.json with correct content" do
      content = extract_entry(pkpass_data, "pass.json")
      parsed = JSON.parse(content)
      expect(parsed["passTypeIdentifier"]).to eq("pass.com.example.membership")
      expect(parsed["serialNumber"]).to eq("123456")
    end

    it "includes images in the ZIP" do
      content = extract_entry(pkpass_data, "logo.png")
      expect(content).to eq(logo_data)
    end

    it "includes manifest.json with SHA-1 hashes of all files" do
      manifest = JSON.parse(extract_entry(pkpass_data, "manifest.json"))

      expect(manifest).to have_key("pass.json")
      expect(manifest).to have_key("logo.png")
      expect(manifest).not_to have_key("manifest.json")
      expect(manifest).not_to have_key("signature")

      pass_json_content = extract_entry(pkpass_data, "pass.json")
      expected_hash = Digest::SHA1.hexdigest(pass_json_content)
      expect(manifest["pass.json"]).to eq(expected_hash)
    end

    it "includes a valid PKCS#7 signature" do
      signature_data = extract_entry(pkpass_data, "signature")
      signature = OpenSSL::PKCS7.new(signature_data)
      expect(signature).to be_detached
    end

    it "creates pass without images" do
      pkpass = described_class.new.create_pass(pass_json)
      entries = zip_entries(pkpass)
      expect(entries).to include("pass.json", "manifest.json", "signature")
      expect(entries).not_to include("logo.png")
    end

    it "includes multiple images" do
      icon_data = "\x00ICON"
      images = {"logo.png" => logo_data, "icon.png" => icon_data}
      pkpass = described_class.new.create_pass(pass_json, images)
      entries = zip_entries(pkpass)
      expect(entries).to include("logo.png", "icon.png")
    end
  end

  describe "#initialize" do
    it "raises when config is missing" do
      Wallets::AppleWallet::Config.instance_variable_set(:@config, nil)
      Wallets::AppleWallet::Config.remove_instance_variable(:@config)
      stub_const("Wallets::AppleWallet::Config::FILE_PATH",
        Rails.root.join("tmp", "nonexistent.yml"))

      expect { described_class.new }.to raise_error(RuntimeError, /not found/)
    end
  end

  private

  def extract_entry(pkpass_data, name)
    Zip::InputStream.open(StringIO.new(pkpass_data)) do |zip|
      while (entry = zip.get_next_entry)
        return entry.get_input_stream.read if entry.name == name
      end
    end
    raise "Entry #{name} not found in pkpass"
  end

  def zip_entries(pkpass_data)
    entries = []
    Zip::InputStream.open(StringIO.new(pkpass_data)) do |zip|
      while (entry = zip.get_next_entry)
        entries << entry.name
      end
    end
    entries
  end
end
