#  Copyright (c) 2025, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe PassMembership do
  let(:definition) { Fabricate(:pass_definition, owner: groups(:top_layer)) }

  subject(:membership) do
    PassMembership.new(
      person: people(:top_leader),
      pass_definition: definition,
      state: :eligible,
      valid_from: Time.zone.today
    )
  end

  it "is valid with default attributes" do
    expect(membership).to be_valid
  end

  context "validations" do
    it "validates person uniqueness per pass_definition" do
      membership.save!
      duplicate = PassMembership.new(
        person: people(:top_leader),
        pass_definition: definition,
        state: :eligible
      )
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:person_id]).to be_present
    end

    it "allows same person with different pass_definition" do
      membership.save!
      other_def = Fabricate(:pass_definition, owner: groups(:top_layer))
      other = PassMembership.new(
        person: people(:top_leader),
        pass_definition: other_def,
        state: :eligible
      )
      expect(other).to be_valid
    end
  end

  context "enum state" do
    it "defaults to eligible" do
      m = PassMembership.new
      expect(m.state).to eq("eligible")
    end

    it "supports eligible state" do
      membership.state = :eligible
      expect(membership).to be_eligible
    end

    it "supports ended state" do
      membership.state = :ended
      expect(membership).to be_ended
    end

    it "supports revoked state" do
      membership.state = :revoked
      expect(membership).to be_revoked
    end
  end

  context "associations" do
    it "belongs to person" do
      expect(membership.person).to eq(people(:top_leader))
    end

    it "belongs to pass_definition" do
      expect(membership.pass_definition).to eq(definition)
    end

    it "has many pass_installations" do
      membership.save!
      installation = Fabricate(:wallets_pass_installation, pass_membership: membership)
      expect(membership.pass_installations).to include(installation)
    end

    it "destroys dependent pass_installations" do
      membership.save!
      Fabricate(:wallets_pass_installation, pass_membership: membership)
      expect { membership.destroy }.to change { Wallets::PassInstallation.count }.by(-1)
    end
  end
end
