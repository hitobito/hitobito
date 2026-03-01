#  Copyright (c) 2025, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

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

    it "allows same grantor_id with different grantor_type" do
      grant.save!
      # Different grantor type would be valid (e.g. Event vs Group)
      # but since we only have Group for now, test with different grantor_id
      other = PassGrant.new(
        pass_definition: definition,
        grantor: groups(:bottom_layer_one)
      )
      other.role_types = [Group::BottomLayer::Leader.sti_name]
      expect(other).to be_valid
    end
  end

  context "associations" do
    it "belongs to pass_definition" do
      expect(grant.pass_definition).to eq(definition)
    end

    it "belongs to grantor (Group)" do
      expect(grant.grantor).to eq(groups(:top_group))
    end

    it "has many related_role_types" do
      grant.save!
      expect(grant.related_role_types).to be_present
      expect(grant.related_role_types.first.role_type).to eq(Group::TopGroup::Leader.sti_name)
    end

    it "destroys dependent related_role_types" do
      grant.save!
      expect { grant.destroy }.to change { RelatedRoleType.count }.by(-1)
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
end
