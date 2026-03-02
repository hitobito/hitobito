#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Wallets::GoogleWallet::PassService do
  let(:person) { people(:top_leader) }
  let(:definition) do
    Fabricate(:pass_definition,
      owner: groups(:top_layer),
      name: "SAC Mitgliedschaft",
      description: "Mitgliedschaftsausweis",
      background_color: "#003366")
  end

  let(:issuer_id) { "3388000000022266745" }
  let(:pass_poro) { Pass.new(person: person, definition: definition) }
  let(:client) { instance_double(Wallets::GoogleWallet::Client) }

  subject(:service) { described_class.new(pass_poro, client: client) }

  before do
    allow(Wallets::GoogleWallet::Config).to receive(:issuer_id).and_return(issuer_id)
    # Default: no logo attached, no application logo fallback
    allow(Settings.application).to receive(:logo).and_return(nil)
  end

  describe "#save_url" do
    it "creates class and object, returns save URL" do
      expect(client).to receive(:create_class).with(kind_of(Hash), type: :generic).ordered
      expect(client).to receive(:create_or_update_object).with(kind_of(Hash), type: :generic).ordered
      expect(client).to receive(:generate_save_url)
        .with("#{issuer_id}.pass_#{person.id}-#{definition.id}", type: :generic)
        .and_return("https://pay.google.com/gp/v/save/jwt-token")
        .ordered

      url = service.save_url
      expect(url).to eq("https://pay.google.com/gp/v/save/jwt-token")
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
    let(:expected_pass_object_id) { "#{issuer_id}.pass_#{person.id}-#{definition.id}" }

    it "sends INACTIVE state to client" do
      expect(client).to receive(:create_or_update_object).with(
        {id: expected_pass_object_id, state: "INACTIVE"},
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

      expect(payload[:id]).to eq("#{issuer_id}.pass_class_#{definition.id}")
      expect(payload[:issuerName]).to eq("SAC Mitgliedschaft")
      expect(payload[:reviewStatus]).to eq("UNDER_REVIEW")
      expect(payload[:multipleDevicesAndHoldersAllowedStatus]).to eq("MULTIPLE_HOLDERS")
      expect(payload[:linksModuleData]).to eq({uris: []})
    end
  end

  describe "generic_object payload" do
    let(:expected_class_id) { "#{issuer_id}.pass_class_#{definition.id}" }
    let(:expected_object_id) { "#{issuer_id}.pass_#{person.id}-#{definition.id}" }

    before do
      allow(client).to receive(:create_class)
      allow(client).to receive(:create_or_update_object)
      allow(client).to receive(:generate_save_url).and_return("https://example.com")
    end

    it "contains required fields" do
      payload = nil
      allow(client).to receive(:create_or_update_object) { |p, **_| payload = p }

      service.save_url

      expect(payload[:id]).to eq(expected_object_id)
      expect(payload[:classId]).to eq(expected_class_id)
      expect(payload[:state]).to eq("ACTIVE")
      expect(payload[:hexBackgroundColor]).to eq("#003366")
    end

    it "includes header with definition name" do
      payload = nil
      allow(client).to receive(:create_or_update_object) { |p, **_| payload = p }

      service.save_url

      expect(payload[:header]).to eq(
        {defaultValue: {language: I18n.locale.to_s, value: "SAC Mitgliedschaft"}}
      )
    end

    it "includes QR barcode with qrcode_value" do
      payload = nil
      allow(client).to receive(:create_or_update_object) { |p, **_| payload = p }

      service.save_url

      expect(payload[:barcode][:type]).to eq("QR_CODE")
      expect(payload[:barcode][:value]).to eq(pass_poro.qrcode_value)
      expect(payload[:barcode][:alternateText]).to eq(pass_poro.member_number)
    end

    it "includes base text modules" do
      payload = nil
      allow(client).to receive(:create_or_update_object) { |p, **_| payload = p }

      service.save_url

      modules = payload[:textModulesData]
      expect(modules.find { |m| m[:id] == "member_name" }[:body]).to eq(person.full_name)
      expect(modules.find { |m| m[:id] == "member_number" }[:body]).to eq(pass_poro.member_number)
      expect(modules.find { |m| m[:id] == "valid_until" }).to be_present
    end

    it "includes description module when definition has description" do
      payload = nil
      allow(client).to receive(:create_or_update_object) { |p, **_| payload = p }

      service.save_url

      desc_module = payload[:textModulesData].find { |m| m[:id] == "description" }
      expect(desc_module[:body]).to eq("Mitgliedschaftsausweis")
      expect(desc_module[:header]).to eq(I18n.t("wallets.pass.description"))
    end

    it "omits description module when definition has no description" do
      definition.update!(description: nil)
      payload = nil
      allow(client).to receive(:create_or_update_object) { |p, **_| payload = p }

      service.save_url

      desc_module = payload[:textModulesData].find { |m| m[:id] == "description" }
      expect(desc_module).to be_nil
    end

    it "includes extra text modules from wallet_data_provider" do
      extra_modules = [{id: "section", header: "Sektion", body: "Bern"}]
      provider = instance_double(Passes::WalletDataProvider,
        member_number: "00000001",
        member_name: person.full_name,
        extra_google_text_modules: extra_modules)
      allow_any_instance_of(Pass).to receive(:wallet_data_provider).and_return(provider)

      payload = nil
      allow(client).to receive(:create_or_update_object) { |p, **_| payload = p }

      service.save_url

      section_module = payload[:textModulesData].find { |m| m[:id] == "section" }
      expect(section_module[:body]).to eq("Bern")
    end
  end

  describe "validTimeInterval" do
    before do
      allow(client).to receive(:create_class)
      allow(client).to receive(:create_or_update_object)
      allow(client).to receive(:generate_save_url).and_return("https://example.com")
    end

    it "includes start date" do
      payload = nil
      allow(client).to receive(:create_or_update_object) { |p, **_| payload = p }

      service.save_url

      interval = payload[:validTimeInterval]
      expect(interval[:start][:date]).to be_present
    end

    it "includes end date when valid_until is set" do
      # Create a role with end_on to give valid_until a value
      grant = Fabricate(:pass_grant, pass_definition: definition, grantor: groups(:top_group))
      grant.role_types = [Group::TopGroup::Leader.sti_name]

      role = person.roles.find_by(type: Group::TopGroup::Leader.sti_name)
      role.update_columns(end_on: 1.year.from_now.to_date) if role

      payload = nil
      allow(client).to receive(:create_or_update_object) { |p, **_| payload = p }

      service.save_url

      if pass_poro.valid_until
        interval = payload[:validTimeInterval]
        expect(interval[:end][:date]).to eq(pass_poro.valid_until.iso8601)
      end
    end

    it "omits end date when valid_until is nil" do
      payload = nil
      allow(client).to receive(:create_or_update_object) { |p, **_| payload = p }

      # Stub valid_until to nil
      allow(pass_poro).to receive(:valid_until).and_return(nil)

      service.save_url

      interval = payload[:validTimeInterval]
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

      payload = nil
      allow(client).to receive(:create_or_update_object) { |p, **_| payload = p }

      service.save_url

      expect(payload[:heroImage]).to be_nil
    end

    it "uses application logo as fallback" do
      logo_config = double("logo", present?: true, image: "logo.png")
      allow(Settings.application).to receive(:logo).and_return(logo_config)
      allow(ActionController::Base.helpers).to receive(:asset_url).with("logo.png").and_return("http://test.host/assets/logo.png")

      payload = nil
      allow(client).to receive(:create_or_update_object) { |p, **_| payload = p }

      service.save_url

      expect(payload[:heroImage]).to eq({sourceUri: {uri: "http://test.host/assets/logo.png"}})
    end
  end
end
