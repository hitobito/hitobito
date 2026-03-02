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

  before do
    allow_any_instance_of(PassPopulateJob).to receive(:enqueue!)
  end

  describe "#perform" do
    it "delegates state calculation to StateCalculator" do
      calculator = instance_double(Passes::StateCalculator)
      allow(Passes::StateCalculator).to receive(:new).and_return(calculator)
      expect(calculator).to receive(:update_state!).once
      expect(Passes::StateCalculator).to receive(:new).with(definition, person).and_return(calculator)

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
      bottom_member = people(:bottom_member)

      described_class.new(definition.id).perform

      expect(Pass.find_by(person: bottom_member, pass_definition: definition)).to be_nil
    end
  end
end
