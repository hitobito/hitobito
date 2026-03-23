# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe Pass do
  let(:definition) { Fabricate(:pass_definition, owner: groups(:top_layer)) }

  subject(:pass) do
    Pass.new(
      person: people(:top_leader),
      pass_definition: definition,
      state: :eligible,
      valid_from: Time.zone.today
    )
  end

  it "is valid with default attributes" do
    expect(pass).to be_valid
  end

  context "enums" do
    it "defines state enum with correct values" do
      expect(Pass.state_labels.keys).to eq [:eligible, :ended, :revoked]
    end
  end

  context "validations" do
    it "validates person uniqueness per pass_definition" do
      pass.save!
      duplicate = Pass.new(
        person: people(:top_leader),
        pass_definition: definition,
        state: :eligible
      )
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:person_id]).to be_present
    end

    it "allows same person with different pass_definition" do
      pass.save!
      other_def = Fabricate(:pass_definition, owner: groups(:top_layer))
      other = Pass.new(
        person: people(:top_leader),
        pass_definition: other_def,
        state: :eligible
      )
      expect(other).to be_valid
    end

    context "state" do
      it "requires state to be eligible on create" do
        invalid = Pass.new(
          person: people(:top_leader),
          pass_definition: definition,
          state: :ended
        )
        expect(invalid).not_to be_valid
        expect(invalid.errors[:state]).to be_present
      end

      it "allows non-eligible state on update" do
        pass.save!
        pass.state = :ended
        expect(pass).to be_valid
      end
    end
  end
end
