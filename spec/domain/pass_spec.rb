#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Pass do
  let(:person) { people(:top_leader) }
  let(:definition) { Fabricate(:pass_definition, owner: groups(:top_layer)) }
  let(:grant) do
    Fabricate(
      :pass_grant,
      pass_definition: definition,
      grantor: groups(:top_group)
    ).tap do |g|
      g.role_types = [Group::TopGroup::Leader.sti_name]
    end
  end

  let(:eligibility) { instance_double(Wallets::PassEligibility) }
  let(:matching_roles) { person.roles.where(type: Group::TopGroup::Leader.sti_name) }
  let(:matching_roles_including_ended) { person.roles.with_inactive.where(type: Group::TopGroup::Leader.sti_name) }

  subject(:pass) { described_class.new(person: person, definition: definition) }

  before do
    # Stub PassEligibility since it's implemented in WP 03b
    stub_const("Wallets::PassEligibility", Class.new) unless defined?(Wallets::PassEligibility)
    allow(Wallets::PassEligibility).to receive(:new).with(definition).and_return(eligibility)
  end

  describe "#eligible?" do
    it "returns true when person has matching roles" do
      allow(eligibility).to receive(:member?).with(person).and_return(true)
      expect(pass).to be_eligible
    end

    it "returns false when person has no matching roles" do
      allow(eligibility).to receive(:member?).with(person).and_return(false)
      expect(pass).not_to be_eligible
    end
  end

  describe "#has_ended?" do
    let(:ended_roles_relation) { double("roles_relation") }

    it "returns true when not eligible but has ended roles" do
      allow(eligibility).to receive(:member?).with(person).and_return(false)
      allow(eligibility).to receive(:matching_roles_including_ended).with(person).and_return(ended_roles_relation)
      allow(ended_roles_relation).to receive(:exists?).and_return(true)

      expect(pass.has_ended?).to be true
    end

    it "returns false when still eligible" do
      allow(eligibility).to receive(:member?).with(person).and_return(true)

      expect(pass.has_ended?).to be false
    end

    it "returns false when not eligible and no ended roles" do
      allow(eligibility).to receive(:member?).with(person).and_return(false)
      allow(eligibility).to receive(:matching_roles_including_ended).with(person).and_return(ended_roles_relation)
      allow(ended_roles_relation).to receive(:exists?).and_return(false)

      expect(pass.has_ended?).to be false
    end
  end

  describe "#valid_from" do
    let(:roles_relation) { double("roles_relation") }

    it "returns the earliest start_on from matching roles" do
      allow(eligibility).to receive(:matching_roles_including_ended).with(person).and_return(roles_relation)
      allow(roles_relation).to receive(:minimum).with(:start_on).and_return(Date.new(2025, 1, 15))

      expect(pass.valid_from).to eq(Date.new(2025, 1, 15))
    end

    it "returns current date when no start_on is set" do
      allow(eligibility).to receive(:matching_roles_including_ended).with(person).and_return(roles_relation)
      allow(roles_relation).to receive(:minimum).with(:start_on).and_return(nil)

      expect(pass.valid_from).to eq(Date.current)
    end
  end

  describe "#valid_until" do
    let(:roles_relation) { double("roles_relation") }

    it "returns the latest end_on from matching roles" do
      allow(eligibility).to receive(:matching_roles_including_ended).with(person).and_return(roles_relation)
      allow(roles_relation).to receive(:maximum).with(:end_on).and_return(Date.new(2026, 12, 31))

      expect(pass.valid_until).to eq(Date.new(2026, 12, 31))
    end

    it "returns nil when roles are unbounded" do
      allow(eligibility).to receive(:matching_roles_including_ended).with(person).and_return(roles_relation)
      allow(roles_relation).to receive(:maximum).with(:end_on).and_return(nil)

      expect(pass.valid_until).to be_nil
    end
  end

  describe "#valid?" do
    let(:roles_relation) { double("roles_relation") }

    before do
      allow(eligibility).to receive(:matching_roles_including_ended).with(person).and_return(roles_relation)
    end

    it "returns true when eligible and within validity period" do
      allow(eligibility).to receive(:member?).with(person).and_return(true)
      allow(roles_relation).to receive(:minimum).with(:start_on).and_return(1.month.ago.to_date)
      allow(roles_relation).to receive(:maximum).with(:end_on).and_return(1.month.from_now.to_date)

      expect(pass).to be_valid
    end

    it "returns true when eligible with open-ended validity" do
      allow(eligibility).to receive(:member?).with(person).and_return(true)
      allow(roles_relation).to receive(:minimum).with(:start_on).and_return(1.month.ago.to_date)
      allow(roles_relation).to receive(:maximum).with(:end_on).and_return(nil)

      expect(pass).to be_valid
    end

    it "returns false when not eligible" do
      allow(eligibility).to receive(:member?).with(person).and_return(false)
      # valid? short-circuits on eligible? check, no need for date stubs

      expect(pass).not_to be_valid
    end

    it "returns false when valid_from is in the future" do
      allow(eligibility).to receive(:member?).with(person).and_return(true)
      allow(roles_relation).to receive(:minimum).with(:start_on).and_return(1.month.from_now.to_date)
      allow(roles_relation).to receive(:maximum).with(:end_on).and_return(2.months.from_now.to_date)

      expect(pass).not_to be_valid
    end

    it "returns false when valid_until is in the past" do
      allow(eligibility).to receive(:member?).with(person).and_return(true)
      allow(roles_relation).to receive(:minimum).with(:start_on).and_return(2.months.ago.to_date)
      allow(roles_relation).to receive(:maximum).with(:end_on).and_return(1.day.ago.to_date)

      expect(pass).not_to be_valid
    end
  end

  describe "#member_number" do
    it "returns zero-padded person id via WalletDataProvider" do
      expect(pass.member_number).to eq(person.id.to_s.rjust(8, "0"))
    end
  end

  describe "#member_name" do
    it "returns person full_name via WalletDataProvider" do
      expect(pass.member_name).to eq(person.full_name)
    end
  end

  describe "#account_id" do
    it "returns person_id-definition_id" do
      definition.save!
      expect(pass.account_id).to eq("#{person.id}-#{definition.id}")
    end
  end

  describe "#qrcode_value" do
    it "returns a verification URL string" do
      definition.save!
      expect(pass.qrcode_value).to be_a(String)
      expect(pass.qrcode_value).to include(definition.id.to_s)
    end
  end

  describe "#to_h" do
    let(:roles_relation) { double("roles_relation") }

    before do
      definition.save!
      allow(eligibility).to receive(:matching_roles_including_ended).with(person).and_return(roles_relation)
      allow(roles_relation).to receive(:minimum).with(:start_on).and_return(Date.new(2025, 6, 1))
      allow(roles_relation).to receive(:maximum).with(:end_on).and_return(Date.new(2026, 5, 31))
    end

    it "returns a hash with all pass data" do
      result = pass.to_h

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
      expect(pass.wallet_data_provider).to be_a(Passes::WalletDataProvider)
    end

    it "passes self to the provider" do
      expect(pass.wallet_data_provider.pass).to eq(pass)
    end

    it "memoizes the provider" do
      expect(pass.wallet_data_provider).to be(pass.wallet_data_provider)
    end
  end
end
