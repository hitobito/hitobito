#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe PassDecorator do
  let(:person) { people(:top_leader) }
  let(:definition) { Fabricate(:pass_definition, owner: groups(:top_layer)) }
  let(:pass_record) do
    Fabricate.build(:pass,
      person: person,
      pass_definition: definition,
      state: :eligible,
      valid_from: 1.month.ago.to_date,
      valid_until: nil)
  end

  subject(:decorator) { described_class.new(pass_record) }

  describe "#logo_group" do
    before { definition.save! }

    it "returns nil when no group in the ancestor chain has a logo" do
      expect(decorator.logo_group).to be_nil
    end

    it "returns the closest ancestor group with a logo attached" do
      groups(:top_layer).logo.attach(
        io: Rails.root.join("spec", "fixtures", "files", "images", "logo.png").open,
        filename: "logo.png",
        content_type: "image/png"
      )
      expect(decorator.logo_group).to eq(groups(:top_layer))
    end
  end

  describe "#logo_blob" do
    before { definition.save! }

    it "returns nil when no logo is configured" do
      allow(Settings.application).to receive(:logo).and_return(nil)
      expect(decorator.logo_blob).to be_nil
    end

    it "returns binary data from the group logo when available" do
      groups(:top_layer).logo.attach(
        io: Rails.root.join("spec", "fixtures", "files", "images", "logo.png").open,
        filename: "logo.png",
        content_type: "image/png"
      )
      blob = decorator.logo_blob
      expect(blob).to be_a(String)
      expect(blob).not_to be_empty
    end
  end

  describe "#logo_url" do
    before { definition.save! }

    it "returns nil when no logo is configured" do
      allow(Settings.application).to receive(:logo).and_return(nil)
      expect(decorator.logo_url).to be_nil
    end

    it "returns a URL for the group logo when available" do
      groups(:top_layer).logo.attach(
        io: Rails.root.join("spec", "fixtures", "files", "images", "logo.png").open,
        filename: "logo.png",
        content_type: "image/png"
      )
      url = decorator.logo_url
      expect(url).to be_a(String)
      expect(url).to include("logo")
    end
  end

  describe "#eligible?" do
    it "returns true when pass state is eligible" do
      pass_record.state = :eligible
      expect(decorator).to be_eligible
    end

    it "returns false when pass state is ended" do
      pass_record.state = :ended
      expect(decorator).not_to be_eligible
    end

    it "returns false when pass state is revoked" do
      pass_record.state = :revoked
      expect(decorator).not_to be_eligible
    end
  end

  describe "#ended?" do
    it "returns true when pass state is ended" do
      pass_record.state = :ended
      expect(decorator).to be_ended
    end

    it "returns false when pass state is eligible" do
      pass_record.state = :eligible
      expect(decorator).not_to be_ended
    end

    it "returns false when pass state is revoked" do
      pass_record.state = :revoked
      expect(decorator).not_to be_ended
    end
  end

  describe "#valid_from" do
    it "reads valid_from from the pass record" do
      pass_record.valid_from = Date.new(2025, 1, 15)
      expect(decorator.valid_from).to eq(Date.new(2025, 1, 15))
    end
  end

  describe "#valid_until" do
    it "reads valid_until from the pass record" do
      pass_record.valid_until = Date.new(2026, 12, 31)
      expect(decorator.valid_until).to eq(Date.new(2026, 12, 31))
    end

    it "returns nil when open-ended" do
      pass_record.valid_until = nil
      expect(decorator.valid_until).to be_nil
    end
  end

  describe "#active?" do
    it "returns true when eligible and within validity period" do
      pass_record.state = :eligible
      pass_record.valid_from = 1.month.ago.to_date
      pass_record.valid_until = 1.month.from_now.to_date
      expect(decorator).to be_active
    end

    it "returns true when eligible with open-ended validity" do
      pass_record.state = :eligible
      pass_record.valid_from = 1.month.ago.to_date
      pass_record.valid_until = nil
      expect(decorator).to be_active
    end

    it "returns false when not eligible" do
      pass_record.state = :ended
      expect(decorator).not_to be_active
    end

    it "returns false when valid_from is in the future" do
      pass_record.state = :eligible
      pass_record.valid_from = 1.month.from_now.to_date
      expect(decorator).not_to be_active
    end

    it "returns false when valid_until is in the past" do
      pass_record.state = :eligible
      pass_record.valid_from = 2.months.ago.to_date
      pass_record.valid_until = 1.day.ago.to_date
      expect(decorator).not_to be_active
    end
  end

  describe "#definition" do
    it "returns the pass_definition from the pass record" do
      expect(decorator.definition).to eq(definition)
    end
  end

  describe "#person" do
    it "delegates to the pass record" do
      expect(decorator.person).to eq(person)
    end
  end

  describe "#member_number" do
    it "returns zero-padded person id via WalletDataProvider" do
      expect(decorator.member_number).to eq(person.id.to_s.rjust(8, "0"))
    end
  end

  describe "#member_name" do
    it "returns person full_name via WalletDataProvider" do
      expect(decorator.member_name).to eq(person.full_name)
    end
  end

  describe "#qrcode_value" do
    it "returns a verification URL string" do
      definition.save!
      expect(decorator.qrcode_value).to be_a(String)
      expect(decorator.qrcode_value).to include(definition.id.to_s)
    end
  end

  describe "#to_h" do
    before { definition.save! }

    it "returns a hash with all pass data" do
      pass_record.valid_from = Date.new(2025, 6, 1)
      pass_record.valid_until = Date.new(2026, 5, 31)

      result = decorator.to_h

      expect(result[:definition_id]).to eq(definition.id)
      expect(result[:definition_name]).to eq(definition.name)
      expect(result[:person_id]).to eq(person.id)
      expect(result[:member_number]).to eq(person.id.to_s.rjust(8, "0"))
      expect(result[:member_name]).to eq(person.full_name)
      expect(result[:valid_from]).to eq(Date.new(2025, 6, 1))
      expect(result[:valid_until]).to eq(Date.new(2026, 5, 31))
      expect(result[:qrcode_value]).to be_a(String)
    end
  end

  describe "#wallet_data_provider" do
    it "returns a WalletDataProvider instance" do
      expect(decorator.wallet_data_provider).to be_a(Passes::WalletDataProvider)
    end

    it "passes self (the decorator) to the provider" do
      expect(decorator.wallet_data_provider.pass).to eq(decorator)
    end

    it "memoizes the provider" do
      expect(decorator.wallet_data_provider).to be(decorator.wallet_data_provider)
    end
  end
end
