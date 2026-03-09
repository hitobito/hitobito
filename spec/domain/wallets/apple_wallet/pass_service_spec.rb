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
  let(:installation) do
    Fabricate(:wallets_pass_installation,
      pass: pass,
      wallet_type: :apple,
      wallet_identifier: "#{person.id}-#{definition.id}")
  end

  let(:client) { instance_double(Wallets::AppleWallet::PkpassGenerator) }

  subject(:service) do
    described_class.new(pass, pass_installation: installation, client: client)
  end

  before do
    allow(Wallets::AppleWallet::Config).to receive(:pass_type_identifier).and_return("pass.com.example.test")
    allow(Wallets::AppleWallet::Config).to receive(:team_identifier).and_return("ABCDE12345")
    allow(Wallets::AppleWallet::Config).to receive(:web_service_url).and_return("https://example.com/api/apple")
  end

  describe "#generate_pass" do
    it "delegates to client and returns binary data" do
      expect(client).to receive(:create_pass).with(kind_of(Hash), kind_of(Hash)).and_return("binary-pkpass-data")

      result = service.generate_pass
      expect(result).to eq("binary-pkpass-data")
    end

    it "passes pass_data hash and images to client" do
      payload = nil
      images = nil
      allow(client).to receive(:create_pass) { |p, i|
        payload = p
        images = i
        "data"
      }

      service.generate_pass

      expect(payload).to be_a(Hash)
      expect(payload[:formatVersion]).to eq(1)
    end
  end

  describe "#pass_data" do
    subject(:data) { service.pass_data }

    it "contains formatVersion" do
      expect(data[:formatVersion]).to eq(1)
    end

    it "contains passTypeIdentifier from Config" do
      expect(data[:passTypeIdentifier]).to eq("pass.com.example.test")
    end

    it "contains serialNumber from pass_installation.wallet_identifier" do
      expect(data[:serialNumber]).to eq(installation.wallet_identifier)
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
      expect(data[:labelColor]).to eq("rgb(255, 255, 255)")
    end

    it "contains webServiceURL from Config" do
      expect(data[:webServiceURL]).to eq("https://example.com/api/apple")
    end

    it "contains authenticationToken from pass_installation" do
      expect(data[:authenticationToken]).to eq(installation.authentication_token)
      expect(data[:authenticationToken]).to be_present
    end

    it "contains barcode with QR code" do
      expect(data[:barcode][:format]).to eq("PKBarcodeFormatQR")
      expect(data[:barcode][:message]).to eq(service.pass.qrcode_value)
      expect(data[:barcode][:messageEncoding]).to eq("iso-8859-1")
      expect(data[:barcode][:altText]).to eq(service.pass.member_number)
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
      expect(primary[:label]).to eq(I18n.t("wallets.apple.member_name"))
    end

    it "includes member_number as secondary field" do
      secondary = generic[:secondaryFields].find { |f| f[:key] == "member_number" }
      expect(secondary[:value]).to eq(service.pass.member_number)
      expect(secondary[:label]).to eq(I18n.t("wallets.pass.member_number"))
    end

    context "with valid_until set" do
      before do
        role = person.roles.first
        role.update_columns(end_on: 1.year.from_now.to_date)

        grant = Fabricate(:pass_grant, pass_definition: definition, grantor: groups(:top_group))
        grant.role_types = [role.type] if role
      end

      it "includes valid_until as auxiliary field with dateStyle" do
        if service.pass.valid_until
          aux = generic[:auxiliaryFields].find { |f| f[:key] == "valid_until" }
          expect(aux[:value]).to eq(service.pass.valid_until.iso8601)
          expect(aux[:dateStyle]).to eq("PKDateStyleShort")
          expect(aux[:label]).to eq(I18n.t("wallets.pass.valid_until"))
        end
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
      expect(back[:label]).to eq(I18n.t("wallets.pass.description"))
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

  describe "voided flag" do
    context "when voided is false (default)" do
      it "does not include voided in compacted output" do
        expect(service.pass_data[:voided]).to eq(false)
      end
    end

    context "when voided is true" do
      subject(:service) do
        described_class.new(pass, pass_installation: installation, client: client, voided: true)
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
        expect(service.pass_data[:expirationDate]).to eq("2026-12-31")
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
end
