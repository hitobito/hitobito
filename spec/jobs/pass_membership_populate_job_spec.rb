#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe PassMembershipPopulateJob do
  let(:definition) { Fabricate(:pass_definition, owner: groups(:top_layer)) }
  let(:person) { people(:top_leader) }

  before do
    allow_any_instance_of(PassMembershipPopulateJob).to receive(:enqueue!)
  end

  let!(:grant) do
    Fabricate(:pass_grant,
      pass_definition: definition,
      grantor: groups(:top_group)).tap do |g|
      g.role_types = [Group::TopGroup::Leader.sti_name]
    end
  end

  describe "#perform" do
    it "creates pass_memberships for eligible people" do
      expect {
        described_class.new(definition.id).perform
      }.to change(PassMembership, :count).by(1)

      membership = PassMembership.find_by(person: person, pass_definition: definition)
      expect(membership.state).to eq("eligible")
      expect(membership.valid_from).to be_present
    end

    it "is idempotent on re-run" do
      described_class.new(definition.id).perform

      expect {
        described_class.new(definition.id).perform
      }.not_to change(PassMembership, :count)
    end

    it "updates existing membership state" do
      # Create an ended membership first
      membership = Fabricate(:pass_membership,
        person: person,
        pass_definition: definition,
        state: :ended,
        valid_from: 1.month.ago.to_date)

      described_class.new(definition.id).perform

      membership.reload
      expect(membership.state).to eq("eligible")
    end

    it "does not create memberships for ineligible people" do
      bottom_member = people(:bottom_member)

      described_class.new(definition.id).perform

      expect(PassMembership.find_by(person: bottom_member, pass_definition: definition)).to be_nil
    end

    it "sets valid_from from earliest matching role start_on" do
      role = roles(:top_leader)
      role.update_columns(start_on: 3.months.ago.to_date)

      described_class.new(definition.id).perform

      membership = PassMembership.find_by(person: person, pass_definition: definition)
      expect(membership.valid_from).to eq(3.months.ago.to_date)
    end
  end
end
