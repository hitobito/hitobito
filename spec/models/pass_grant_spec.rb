# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe PassGrant do
  let(:definition) { Fabricate(:pass_definition, owner: groups(:top_layer)) }

  subject(:grant) do
    PassGrant.new(
      pass_definition: definition,
      grantor: groups(:top_group)
    ).tap do |g|
      g.role_types = [Group::TopGroup::Leader.sti_name]
    end
  end

  it "is valid with default attributes" do
    expect(grant).to be_valid
  end

  context "validations" do
    it "requires at least one related_role_type" do
      grant.role_types = []
      expect(grant).not_to be_valid
      expect(grant.errors[:related_role_types]).to be_present
    end

    it "validates grantor uniqueness per pass_definition and grantor_type" do
      grant.save!
      duplicate = PassGrant.new(
        pass_definition: definition,
        grantor: groups(:top_group)
      )
      duplicate.role_types = [Group::TopGroup::Member.sti_name]
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:grantor_id]).to be_present
    end

    it "allows same grantor with different pass_definition" do
      grant.save!
      other_def = Fabricate(:pass_definition, owner: groups(:top_layer))
      other = PassGrant.new(
        pass_definition: other_def,
        grantor: groups(:top_group)
      )
      other.role_types = [Group::TopGroup::Leader.sti_name]
      expect(other).to be_valid
    end
  end

  context "RelatedRoleType::Assigners" do
    it "provides role_types accessor" do
      expect(grant.role_types).to eq([Group::TopGroup::Leader.sti_name])
    end

    it "allows setting role_types" do
      grant.role_types = [Group::TopGroup::Leader.sti_name, Group::TopGroup::Member.sti_name]
      expect(grant.role_types).to contain_exactly(
        Group::TopGroup::Leader.sti_name,
        Group::TopGroup::Member.sti_name
      )
    end
  end

  context "callbacks" do
    it "enqueues PassPopulateJob after save" do
      expect {
        grant.save!
      }.to change { Delayed::Job.where("handler LIKE '%PassPopulateJob%'").count }.by_at_least(1)
    end

    it "enqueues PassPopulateJob again after update" do
      grant.save!
      expect {
        grant.update!(role_types: [Group::TopGroup::Member.sti_name])
      }.to change { Delayed::Job.where("handler LIKE '%PassPopulateJob%'").count }.by(1)
    end
  end
end
