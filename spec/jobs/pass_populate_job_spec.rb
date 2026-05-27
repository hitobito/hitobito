# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe PassPopulateJob do
  let(:definition) { pass_definitions(:top_layer_pass) }
  let(:grant) { pass_grants(:top_layer_grant) }
  let(:person) { people(:top_leader) }
  let(:bottom_member) { people(:bottom_member) }

  before do
    allow_any_instance_of(PassPopulateJob).to receive(:enqueue!)
  end

  describe "#perform" do
    it "delegates state persistence to PassUpdater" do
      expect(Passes::PassUpdater).to receive(:recompute_state!).once
      described_class.new(definition.id).perform
    end

    it "creates passes for eligible people" do
      expect {
        described_class.new(definition.id).perform
      }.to change(Pass, :count).by(1)

      pass = Pass.find_by(person: person, pass_definition: definition)
      expect(pass).to be_present
    end

    it "is idempotent on re-run" do
      described_class.new(definition.id).perform

      expect {
        described_class.new(definition.id).perform
      }.not_to change(Pass, :count)
    end

    it "updates existing passes" do
      pass = Fabricate(:pass,
        person: person,
        pass_definition: definition,
        state: :eligible)
      pass.update_column(:state, "ended")

      expect {
        described_class.new(definition.id).perform
      }.not_to change(Pass, :count)

      expect(pass.reload.state).to eq("eligible")
    end

    it "does not create passes for ineligible people" do
      described_class.new(definition.id).perform

      expect(Pass.find_by(person: bottom_member, pass_definition: definition)).to be_nil
    end

    it "ignores and continous on PG::UniqueViolation" do
      pass = Fabricate(:pass, person: person, pass_definition: definition, state: :eligible)
      pass.update_column(:state, "ended")

      Fabricate(Group::TopGroup::Leader.sti_name, group: groups(:top_group), person: bottom_member)
      recompute_state = Passes::PassUpdater.method(:recompute_state!)

      expect(Passes::PassUpdater).to receive(:recompute_state!).twice do |pass|
        fail PG::UniqueViolation if pass.person == bottom_member
        recompute_state.call(pass)
      end

      expect {
        described_class.new(definition.id).perform
      }.to not_change(Pass, :count)
        .and change { pass.reload.state }.to eq("eligible")
    end
  end
end
