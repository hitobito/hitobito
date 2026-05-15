#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"
require "zip"

describe Wallets::AppleWallet::PkpassGenerator do
  let(:tmp_dir) { Rails.root.join("tmp", "apple_wallet_test") }
  let(:cert_path) { tmp_dir.join("test_cert.pem").to_s }
  let(:key_path) { tmp_dir.join("test_key.pem").to_s }
  let(:wwdr_path) { tmp_dir.join("wwdr.cer").to_s }

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

  # Mock config with test certificate paths
  let(:mock_config) do
    class_double(Wallets::AppleWallet::Config,
      exist?: true,
      pass_type_identifier: "pass.com.example.membership",
      team_identifier: "ABC123DEF4",
      certificate_path: cert_path,
      key_path: key_path,
      key_password: "",
      wwdr_certificate_path: wwdr_path,
      web_service_url: "https://app.example.com/wallets/apple",
      certificate: pass_cert,
      key: pass_key,
      wwdr_certificate: ca_cert)
  end

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

    # Write certificate and key files
    File.write(cert_path, pass_cert.to_pem)
    File.write(key_path, pass_key.to_pem)
    File.binwrite(wwdr_path, ca_cert.to_der)
  end

  after do
    FileUtils.rm_rf(tmp_dir)
  end

  describe "#create_pass" do
    subject(:pkpass_data) { described_class.new(mock_config).create_pass(pass_json, images) }

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
      pkpass = described_class.new(mock_config).create_pass(pass_json)
      entries = zip_entries(pkpass)
      expect(entries).to include("pass.json", "manifest.json", "signature")
      expect(entries).not_to include("logo.png")
    end

    it "includes multiple images" do
      icon_data = "\x00ICON"
      images = {"logo.png" => logo_data, "icon.png" => icon_data}
      pkpass = described_class.new(mock_config).create_pass(pass_json, images)
      entries = zip_entries(pkpass)
      expect(entries).to include("logo.png", "icon.png")
    end

    it "includes localized strings in subdirectories" do
      strings = {
        "pass.strings" => '"key" = "value";',
        "de.lproj/pass.strings" => '"key" = "Wert";',
        "fr.lproj/pass.strings" => '"key" = "valeur";'
      }
      pkpass = described_class.new(mock_config).create_pass(pass_json, {}, strings)
      entries = zip_entries(pkpass)

      expect(entries).to include("pass.strings")
      expect(entries).to include("de.lproj/pass.strings")
      expect(entries).to include("fr.lproj/pass.strings")
    end

    it "includes localized strings in manifest with correct paths" do
      strings = {"de.lproj/pass.strings" => '"key" = "Wert";'}
      pkpass = described_class.new(mock_config).create_pass(pass_json, {}, strings)

      manifest_content = extract_entry(pkpass, "manifest.json")
      manifest = JSON.parse(manifest_content)

      expect(manifest).to have_key("de.lproj/pass.strings")
    end
  end

  describe "#initialize" do
    it "raises when config is missing" do
      class_double("Wallets::AppleWallet::Config", exist?: false).as_stubbed_const
      stub_const("Wallets::AppleWallet::Config::FILE_PATH", Pathname.new("/fake/path.yml"))

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
