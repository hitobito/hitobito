#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Wallets::GoogleWallet::PassService do
  let(:person) { people(:top_leader) }
  let(:definition) { pass_definitions(:top_layer_pass) }

  let(:issuer_id) { "42" }
  let(:client) { instance_double(Wallets::GoogleWallet::Client) }
  let(:top_leader_pass) do
    Fabricate(:pass,
      person: person,
      pass_definition: definition,
      state: :eligible,
      valid_from: Date.current)
  end
  let(:pass_installation) do
    Fabricate(:wallets_pass_installation,
      pass: top_leader_pass,
      wallet_type: :google)
  end

  subject(:service) { described_class.new(pass_installation, client: client) }

  let(:create_or_update_payload) do
    captured_payload = nil
    allow(client).to receive(:create_or_update_object) { |p, **_| captured_payload = p }
    service.save_url
    captured_payload
  end

  before do
    allow(Wallets::GoogleWallet::Config).to receive(:issuer_id).and_return(issuer_id)
    # Default: no logo attached, no application logo fallback
    allow(Settings.application).to receive(:logo).and_return(nil)
  end

  describe "#save_url" do
    it "creates class and object, returns save URL" do
      expect(client).to receive(:create_class).with(kind_of(Hash), type: :generic).ordered
      expect(client).to receive(:create_or_update_object).with(kind_of(Hash), type: :generic).ordered

      expected_id = "#{issuer_id}.hitobito.pass.#{service.pass.id}.#{pass_installation.id}"
      expect(client).to receive(:generate_save_url)
        .with(expected_id, type: :generic)
        .and_return("https://pay.google.com/gp/v/save/jwt-token")
        .ordered

      expect(service.save_url).to eq("https://pay.google.com/gp/v/save/jwt-token")
    end
  end

  describe "#create_or_update" do
    it "creates class and object without generating URL" do
      expect(client).to receive(:create_class).with(kind_of(Hash), type: :generic)
      expect(client).to receive(:create_or_update_object).with(kind_of(Hash), type: :generic)
      expect(client).not_to receive(:generate_save_url)

      service.create_or_update
    end
  end

  describe "#revoke" do
    it "sends INACTIVE state to client" do
      expected_id = "#{issuer_id}.hitobito.pass.#{service.pass.id}.#{pass_installation.id}"

      expect(client).to receive(:create_or_update_object).with(
        {id: expected_id, state: "INACTIVE"},
        type: :generic
      )

      service.revoke
    end
  end

  describe "generic_class payload" do
    before do
      allow(client).to receive(:create_class)
      allow(client).to receive(:create_or_update_object)
      allow(client).to receive(:generate_save_url).and_return("https://example.com")
    end

    it "contains required fields" do
      payload = nil
      allow(client).to receive(:create_class) { |p, **_| payload = p }

      service.save_url

      expect(payload[:id]).to eq("#{issuer_id}.hitobito.class.#{definition.id}")
      expect(payload[:issuerName]).to eq("TopLayer Member Pass")
      expect(payload[:reviewStatus]).to eq("UNDER_REVIEW")
      expect(payload[:multipleDevicesAndHoldersAllowedStatus]).to eq("MULTIPLE_HOLDERS")
      expect(payload[:securityAnimation]).to eq({animationType: "FOIL_SHIMMER"})
    end
  end

  describe "generic_object payload" do
    let(:expected_class_id) { "#{issuer_id}.hitobito.class.#{definition.id}" }
    let(:expected_object_id) {
      "#{issuer_id}.hitobito.pass.#{service.pass.id}.#{pass_installation.id}"
    }
    let(:pass) { service.pass }

    before do
      allow(client).to receive(:create_class)
      allow(client).to receive(:create_or_update_object)
      allow(client).to receive(:generate_save_url).and_return("https://example.com")
    end

    it "contains required fields" do
      expect(create_or_update_payload[:id]).to eq(expected_object_id)
      expect(create_or_update_payload[:classId]).to eq(expected_class_id)
      expect(create_or_update_payload[:state]).to eq("ACTIVE")
      expect(create_or_update_payload[:hexBackgroundColor]).to eq("#0066cc")
    end

    it "includes cardTitle with definition name" do
      expect(create_or_update_payload[:cardTitle]).to eq(
        {defaultValue: {language: I18n.locale.to_s, value: "TopLayer Member Pass"}}
      )
    end

    it "includes header with member name" do
      expect(create_or_update_payload[:header]).to eq(
        {defaultValue: {language: I18n.locale.to_s, value: person.full_name}}
      )
    end

    it "includes QR barcode with qrcode_value" do
      expect(create_or_update_payload[:barcode][:type]).to eq("QR_CODE")
      expect(create_or_update_payload[:barcode][:value]).to eq(pass.qrcode_value)
      expect(create_or_update_payload[:barcode][:alternateText]).to eq(pass.member_number)
    end

    it "includes base text modules" do
      modules = create_or_update_payload[:textModulesData]
      expect(modules.find { |m| m[:id] == "member_name" }[:body]).to eq(person.full_name)
      expect(modules.find { |m| m[:id] == "member_number" }[:body]).to eq(pass.member_number)
      expect(modules.find { |m| m[:id] == "valid_until" }).to be_present
    end

    it "includes description module when definition has description" do
      desc_module = create_or_update_payload[:textModulesData].find { |m| m[:id] == "description" }
      expect(desc_module[:body]).to eq("Pass für TopLayer Mitglieder")
      expect(desc_module[:header]).to eq(I18n.t("wallets.pass.description"))
    end

    it "omits description module when definition has no description" do
      allow(definition).to receive(:description).and_return(nil)

      desc_module = create_or_update_payload[:textModulesData].find { |m| m[:id] == "description" }
      expect(desc_module).to be_nil
    end

    it "includes extra text modules from wallet_data_provider" do
      extra_modules = [{id: "section", header: "Sektion", body: "Bern"}]
      provider = instance_double(Passes::WalletDataProvider,
        member_number: "00000001",
        member_name: person.full_name,
        extra_google_text_modules: extra_modules)
      allow_any_instance_of(PassDecorator).to receive(:wallet_data_provider).and_return(provider)

      section_module = create_or_update_payload[:textModulesData].find { |m| m[:id] == "section" }
      expect(section_module[:body]).to eq("Bern")
    end
  end

  describe "validTimeInterval" do
    let(:pass) { service.pass }

    before do
      allow(client).to receive(:create_class)
      allow(client).to receive(:create_or_update_object)
      allow(client).to receive(:generate_save_url).and_return("https://example.com")
    end

    it "includes start date" do
      interval = create_or_update_payload[:validTimeInterval]
      expect(interval[:start][:date]).to be_present
    end

    it "includes end date when valid_until is set" do
      # Create a role with end_on to give valid_until a value
      grant = Fabricate(:pass_grant, pass_definition: definition, grantor: groups(:top_group))
      grant.role_types = [Group::TopGroup::Leader.sti_name]

      roles(:top_leader).update_columns(end_on: 1.year.from_now.to_date)

      if pass.valid_until
        interval = create_or_update_payload[:validTimeInterval]
        expect(interval[:end][:date]).to eq(pass.valid_until.iso8601)
      end
    end

    it "omits end date when valid_until is nil" do
      # Stub valid_until to nil
      allow(pass).to receive(:valid_until).and_return(nil)

      interval = create_or_update_payload[:validTimeInterval]
      expect(interval).not_to have_key(:end)
    end
  end

  describe "logo resolution" do
    before do
      allow(client).to receive(:create_class)
      allow(client).to receive(:create_or_update_object)
      allow(client).to receive(:generate_save_url).and_return("https://example.com")
    end

    it "returns nil image when no logo is attached and no application logo" do
      allow(Settings.application).to receive(:logo).and_return(nil)

      expect(create_or_update_payload[:heroImage]).to be_nil
    end

    it "uses application logo as fallback" do
      logo_url = "http://test.host/packs/media/images/logo.png"
      allow_any_instance_of(PassDecorator).to receive(:logo_url).and_return(logo_url)

      expect(create_or_update_payload[:heroImage]).to eq({sourceUri: {uri: logo_url}})
    end
  end
end
