#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Wallets::AppleWallet::PassService do
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
  let(:installation) { Fabricate(:wallets_pass_installation, pass: pass, wallet_type: :apple) }

  let(:client) { instance_double(Wallets::AppleWallet::PkpassGenerator) }

  let(:mock_config) do
    class_double(Wallets::AppleWallet::Config,
      pass_type_identifier: "pass.com.example.test",
      team_identifier: "ABCDE12345")
  end

  subject(:service) do
    described_class.new(installation, client: client, config: mock_config)
  end

  describe "#generate_pass" do
    it "delegates to client and returns binary data" do
      expect(client).to receive(:create_pass).with(kind_of(Hash), kind_of(Hash),
        kind_of(Hash)).and_return("binary-pkpass-data")

      result = service.generate_pass
      expect(result).to eq("binary-pkpass-data")
    end

    it "passes pass_data hash and images to client" do
      payload = nil
      allow(client).to receive(:create_pass) { |p| payload = p }
      service.generate_pass

      expect(payload).to be_a(Hash)
      expect(payload[:formatVersion]).to eq(1)
    end
  end

  describe "#pass_data" do
    subject(:data) { service.pass_data }

    after { described_class.id_prefix_addition = nil }

    it "contains formatVersion" do
      expect(data[:formatVersion]).to eq(1)
    end

    it "contains passTypeIdentifier from Config" do
      expect(data[:passTypeIdentifier]).to eq("pass.com.example.test")
    end

    it "contains serialNumber from pass_installation.wallet_identifier" do
      expect(data[:serialNumber]).to eq("hitobito.#{installation.id}")
    end

    it "contains serialNumber contains custom prefix if set" do
      described_class.id_prefix_addition = -> { :test }
      expect(data[:serialNumber]).to eq("hitobito.test.#{installation.id}")
    end

    it "contains teamIdentifier from Config" do
      expect(data[:teamIdentifier]).to eq("ABCDE12345")
    end

    it "contains organizationName from definition" do
      expect(data[:organizationName]).to eq("SAC Mitgliedschaft")
    end

    it "contains description from definition name" do
      expect(data[:description]).to eq("SAC Mitgliedschaft")
    end

    it "contains foregroundColor as white rgb" do
      expect(data[:foregroundColor]).to eq("rgb(255, 255, 255)")
    end

    it "contains backgroundColor converted from hex to rgb" do
      expect(data[:backgroundColor]).to eq("rgb(0, 51, 102)")
    end

    it "contains labelColor as white rgb" do
      expect(data[:labelColor]).to eq("rgb(170, 170, 170)")
    end

    it "contains webServiceURL generated from Rails URL config" do
      expect(data[:webServiceURL]).to eq("https://hitobito.example.com/wallets/apple/v1")
    end

    it "contains authenticationToken from pass_installation" do
      expect(data[:authenticationToken]).to eq(installation.authentication_token)
      expect(data[:authenticationToken]).to be_present
    end

    it "contains barcode with QR code" do
      expect(data[:barcode][:format]).to eq("PKBarcodeFormatQR")
      expect(data[:barcode][:message]).to eq(service.pass.qrcode_value)
      expect(data[:barcode][:messageEncoding]).to eq("iso-8859-1")
      expect(data[:barcode][:altText]).to eq(service.pass.member_number.to_s)
    end

    it "contains barcodes array with single barcode" do
      expect(data[:barcodes]).to be_an(Array)
      expect(data[:barcodes].length).to eq(1)
      expect(data[:barcodes].first[:format]).to eq("PKBarcodeFormatQR")
    end

    it "contains generic style fields" do
      generic = data[:generic]
      expect(generic).to be_present
      expect(generic[:primaryFields]).to be_an(Array)
      expect(generic[:secondaryFields]).to be_an(Array)
      expect(generic[:auxiliaryFields]).to be_an(Array)
    end
  end

  describe "generic style" do
    subject(:generic) { service.pass_data[:generic] }

    it "includes member_name as primary field" do
      primary = generic[:primaryFields].find { |f| f[:key] == "member_name" }
      expect(primary[:value]).to eq(person.full_name)
      expect(primary[:label]).to eq("member_name_label")
    end

    it "includes member_number as secondary field" do
      secondary = generic[:secondaryFields].find { |f| f[:key] == "member_number" }
      expect(secondary[:value]).to eq(service.pass.member_number)
      expect(secondary[:label]).to eq("member_number_label")
    end

    context "with valid_until set" do
      before do
        allow(service.pass).to receive(:valid_until).and_return(Date.new(2026, 12, 31))
      end

      it "includes valid_until as auxiliary field with dateStyle" do
        aux = generic[:auxiliaryFields].find { |f| f[:key] == "valid_until" }
        expect(aux[:value]).to eq(service.pass.valid_until.end_of_day.iso8601)
        expect(aux[:dateStyle]).to eq("PKDateStyleShort")
        expect(aux[:timeStyle]).to eq("PKDateStyleNone")
        expect(aux[:label]).to eq("valid_until_label")
      end
    end

    context "without valid_until" do
      before do
        allow(service.pass).to receive(:valid_until).and_return(nil)
      end

      it "omits valid_until from auxiliary fields" do
        aux = generic[:auxiliaryFields].find { |f| f[:key] == "valid_until" }
        expect(aux).to be_nil
      end
    end

    it "includes description in backFields when definition has description" do
      back = generic[:backFields].find { |f| f[:key] == "description" }
      expect(back[:value]).to eq("Mitgliedschaftsausweis")
      expect(back[:label]).to eq("description_label")
    end

    context "without description" do
      before { definition.update!(description: nil) }

      it "omits backFields description" do
        back = generic[:backFields]
        expect(back).to be_empty
      end
    end

    it "includes extra apple fields from wallet_data_provider" do
      extra_fields = {secondaryFields: [{key: "section", label: "Sektion", value: "Bern"}]}
      provider = instance_double(Passes::WalletDataProvider,
        member_number: "00000001",
        member_name: person.full_name,
        extra_apple_fields: extra_fields)
      allow(service.pass).to receive(:wallet_data_provider).and_return(provider)

      section_field = generic[:secondaryFields].find { |f| f[:key] == "section" }
      expect(section_field[:value]).to eq("Bern")
    end
  end

  describe "#pass_strings" do
    subject(:strings) { service.pass_strings }

    it "generates strings for all languages" do
      Globalized.languages.each do |lang|
        expect(strings).to have_key("#{lang}.lproj/pass.strings")
      end
    end

    it "includes root-level fallback" do
      expect(strings).to have_key("pass.strings")
    end

    it "generates strings in correct format" do
      expect(strings["de.lproj/pass.strings"]).to match(/"member_name_label" = ".*";/)
    end

    it "contains all required label keys" do
      expected_keys = [
        "member_name_label",
        "member_number_label",
        "valid_until_label",
        "description_label"
      ]

      expected_keys.each do |key|
        expect(strings["pass.strings"]).to match(/"#{key}" = ".*";/)
      end
    end
  end

  describe "voided flag" do
    context "when voided is false (default)" do
      it "does not include voided in compacted output" do
        expect(service.pass_data[:voided]).to eq(false)
      end
    end

    context "when voided is true" do
      subject(:service) do
        described_class.new(installation, client: client, voided: true, config: mock_config)
      end

      it "sets voided to true" do
        expect(service.pass_data[:voided]).to eq(true)
      end
    end
  end

  describe "expirationDate" do
    context "with valid_until" do
      before do
        allow(service.pass).to receive(:valid_until).and_return(Date.new(2026, 12, 31))
      end

      it "sets expirationDate to iso8601" do
        expect(service.pass_data[:expirationDate]).to eq("2026-12-31T23:59:59+01:00")
      end
    end

    context "without valid_until" do
      before do
        allow(service.pass).to receive(:valid_until).and_return(nil)
      end

      it "omits expirationDate from compacted output" do
        expect(service.pass_data).not_to have_key(:expirationDate)
      end
    end
  end

  describe "hex_to_rgb conversion" do
    it "converts default background color" do
      definition.update!(background_color: "#0066cc")
      data = service.pass_data
      expect(data[:backgroundColor]).to eq("rgb(0, 102, 204)")
    end

    it "converts black" do
      definition.update!(background_color: "#000000")
      data = service.pass_data
      expect(data[:backgroundColor]).to eq("rgb(0, 0, 0)")
    end

    it "converts white" do
      definition.update!(background_color: "#ffffff")
      data = service.pass_data
      expect(data[:backgroundColor]).to eq("rgb(255, 255, 255)")
    end
  end

  describe "#web_service_url" do
    it "generates URL from Settings.application (same as GoogleWallet)" do
      expect(service.send(:web_service_url)).to eq("https://hitobito.example.com/wallets/apple/v1")
    end

    it "uses Settings.application.protocol and .hostname" do
      allow(Settings.application).to receive(:protocol).and_return("http")
      allow(Settings.application).to receive(:hostname).and_return("test.example.com")

      expect(service.send(:web_service_url)).to eq("http://test.example.com/wallets/apple/v1")
    end
  end

  describe "Integration: end-to-end pass generation" do
    it "generates valid pkpass with all expected contents" do
      # Setup temporary directory for certificates
      tmp_dir = Rails.root.join("tmp", "apple_wallet_integration_test")
      FileUtils.mkdir_p(tmp_dir)

      # Generate self-signed test certificates
      ca_key = OpenSSL::PKey::RSA.new(2048)
      ca_cert = OpenSSL::X509::Certificate.new
      ca_cert.version = 2
      ca_cert.serial = 1
      ca_cert.subject = OpenSSL::X509::Name.parse("/CN=Test WWDR CA")
      ca_cert.issuer = ca_cert.subject
      ca_cert.public_key = ca_key.public_key
      ca_cert.not_before = Time.current - 3600
      ca_cert.not_after = Time.current + 3600
      ca_cert.sign(ca_key, OpenSSL::Digest.new("SHA256"))

      pass_key = OpenSSL::PKey::RSA.new(2048)
      pass_cert = OpenSSL::X509::Certificate.new
      pass_cert.version = 2
      pass_cert.serial = 2
      pass_cert.subject = OpenSSL::X509::Name.parse("/CN=Test Pass Certificate")
      pass_cert.issuer = ca_cert.subject
      pass_cert.public_key = pass_key.public_key
      pass_cert.not_before = Time.current - 3600
      pass_cert.not_after = Time.current + 3600
      pass_cert.sign(ca_key, OpenSSL::Digest.new("SHA256"))

      # Write certificates to disk
      cert_path = tmp_dir.join("test_cert.pem").to_s
      key_path = tmp_dir.join("test_key.pem").to_s
      wwdr_path = tmp_dir.join("wwdr.cer").to_s
      File.write(cert_path, pass_cert.to_pem)
      File.write(key_path, pass_key.to_pem)
      File.binwrite(wwdr_path, ca_cert.to_der)

      # Create config and client
      config = class_double(Wallets::AppleWallet::Config,
        exist?: true,
        pass_type_identifier: "pass.com.example.test",
        team_identifier: "ABCDE12345",
        certificate_path: cert_path,
        key_path: key_path,
        key_password: "",
        wwdr_certificate_path: wwdr_path,
        certificate: pass_cert,
        key: pass_key,
        wwdr_certificate: ca_cert)
      client = Wallets::AppleWallet::PkpassGenerator.new(config)

      # Create pass with expiry date
      pass = Fabricate(:pass, person: person, pass_definition: definition,
        state: :eligible, valid_from: Date.new(2026, 1, 1))

      # Set up role with end date and grant to calculate valid_until
      role = person.roles.first
      role.update_columns(end_on: Date.new(2026, 12, 31))
      grant = Fabricate(:pass_grant, pass_definition: definition, grantor: groups(:top_group))
      grant.role_types = [role.type] if role
      Passes::PassUpdater.recompute_state!(pass)

      # Create installation
      installation = Fabricate(:wallets_pass_installation, pass: pass, wallet_type: :apple)

      # Verify images are attached (by fabricator)
      expect(definition.logo_icon_de).to be_attached
      expect(definition.logo_banner_de).to be_attached

      # Generate the pkpass
      service = described_class.new(installation, client: client, config: config)
      pkpass_data = service.generate_pass

      # Verify it's a binary ZIP file
      expect(pkpass_data).to be_a(String)
      expect(pkpass_data.encoding).to eq(Encoding::ASCII_8BIT)

      # Extract and verify pass.json
      pass_json_content = extract_zip_entry(pkpass_data, "pass.json")
      pass_json = JSON.parse(pass_json_content)

      # Verify expirationDate is in W3C datetime format
      expect(pass_json["expirationDate"]).to match(/^2026-12-31T23:59:59[+-]\d{2}:\d{2}$/)

      # Verify altText is a string
      expect(pass_json["barcode"]["altText"]).to be_a(String)
      expect(pass_json["barcode"]["format"]).to eq("PKBarcodeFormatQR")

      # Verify generic style fields
      expect(pass_json["generic"]["primaryFields"].first["key"]).to eq("member_name")
      expect(pass_json["generic"]["secondaryFields"].first["key"]).to eq("member_number")

      # Verify auxiliary field (valid_until) has correct styles
      valid_until_field = pass_json["generic"]["auxiliaryFields"].find { |f| f["key"] == "valid_until" }
      expect(valid_until_field["dateStyle"]).to eq("PKDateStyleShort")
      expect(valid_until_field["timeStyle"]).to eq("PKDateStyleNone")

      # Verify images are present and not empty
      logo_content = extract_zip_entry(pkpass_data, "logo.png")
      expect(logo_content).not_to be_empty
      expect(logo_content.size).to be > 0

      icon_content = extract_zip_entry(pkpass_data, "icon.png")
      expect(icon_content).not_to be_empty

      # Verify localized strings files exist
      expect(zip_entry_exists?(pkpass_data, "pass.strings")).to be true
      expect(zip_entry_exists?(pkpass_data, "de.lproj/pass.strings")).to be true

      # Verify strings contain all required keys
      strings_content = extract_zip_entry(pkpass_data, "pass.strings")
      expect(strings_content).to include("member_name_label")
      expect(strings_content).to include("member_number_label")
      expect(strings_content).to include("valid_until_label")
      expect(strings_content).to include("description_label")

      # Verify manifest and signature exist
      expect(zip_entry_exists?(pkpass_data, "manifest.json")).to be true
      expect(zip_entry_exists?(pkpass_data, "signature")).to be true

      # Verify manifest contains all files with SHA-1 hashes
      manifest = JSON.parse(extract_zip_entry(pkpass_data, "manifest.json"))
      expect(manifest).to have_key("pass.json")
      expect(manifest).to have_key("logo.png")
      expect(manifest["pass.json"]).to match(/^[0-9a-f]{40}$/)
    ensure
      # Cleanup
      FileUtils.rm_rf(tmp_dir)
    end

    private

    def extract_zip_entry(pkpass_data, name)
      require "zip"
      Zip::InputStream.open(StringIO.new(pkpass_data)) do |zip|
        while (entry = zip.get_next_entry)
          return entry.get_input_stream.read if entry.name == name
        end
      end
      raise "Entry #{name} not found in pkpass"
    end

    def zip_entry_exists?(pkpass_data, name)
      require "zip"
      Zip::InputStream.open(StringIO.new(pkpass_data)) do |zip|
        while (entry = zip.get_next_entry)
          return true if entry.name == name
        end
      end
      false
    end
  end
end
