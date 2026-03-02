#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Wallets::PassEligibility do
  # Fixture hierarchy (nested-set lft/rgt):
  #
  # top_layer (1..18)
  # ├── bottom_layer_one (2..9)
  # │   ├── bottom_group_one_one (3..6)
  # │   │   └── bottom_group_one_one_one (4..5)
  # │   └── bottom_group_one_two (7..8)
  # ├── bottom_layer_two (10..13)
  # │   └── bottom_group_two_one (11..12)
  # ├── top_group (14..15)
  # └── toppers (16..17)

  let(:top_leader) { people(:top_leader) }
  let(:bottom_member) { people(:bottom_member) }

  let(:definition) { Fabricate(:pass_definition, owner: groups(:top_layer)) }
  let(:eligibility) { described_class.new(definition) }

  def create_grant(grantor:, role_types:)
    Fabricate(:pass_grant,
      pass_definition: definition,
      grantor: grantor).tap do |g|
      g.role_types = role_types.map(&:sti_name)
    end
  end

  def create_role(person:, group:, type:, start_on: nil, end_on: nil, archived_at: nil)
    Fabricate(:role,
      person: person,
      group: group,
      type: type.sti_name,
      start_on: start_on,
      end_on: end_on,
      archived_at: archived_at)
  end

  describe "#people" do
    it "returns people with matching active roles in grant subtree" do
      create_grant(grantor: groups(:top_group), role_types: [Group::TopGroup::Leader])

      # top_leader has Group::TopGroup::Leader in top_group (fixture)
      expect(eligibility.people).to include(top_leader)
    end

    it "returns people from child groups within the subtree" do
      create_grant(grantor: groups(:bottom_layer_one), role_types: [Group::BottomGroup::Member])

      person = Fabricate(:person)
      create_role(person: person, group: groups(:bottom_group_one_one), type: Group::BottomGroup::Member)

      expect(eligibility.people).to include(person)
    end

    it "excludes people from groups outside the subtree" do
      create_grant(grantor: groups(:bottom_layer_one), role_types: [Group::BottomGroup::Member])

      person = Fabricate(:person)
      create_role(person: person, group: groups(:bottom_group_two_one), type: Group::BottomGroup::Member)

      expect(eligibility.people).not_to include(person)
    end

    it "excludes people with non-matching role types" do
      create_grant(grantor: groups(:top_group), role_types: [Group::TopGroup::Secretary])

      # top_leader has Leader, not Secretary
      expect(eligibility.people).not_to include(top_leader)
    end

    it "excludes archived roles" do
      create_grant(grantor: groups(:top_group), role_types: [Group::TopGroup::Member])

      person = Fabricate(:person)
      create_role(person: person, group: groups(:top_group), type: Group::TopGroup::Member,
        archived_at: 1.day.ago)

      expect(eligibility.people).not_to include(person)
    end

    it "excludes ended roles (end_on in the past)" do
      create_grant(grantor: groups(:top_group), role_types: [Group::TopGroup::Member])

      person = Fabricate(:person)
      create_role(person: person, group: groups(:top_group), type: Group::TopGroup::Member,
        start_on: 2.months.ago.to_date, end_on: 1.day.ago.to_date)

      expect(eligibility.people).not_to include(person)
    end

    it "returns distinct people even with multiple matching grants" do
      create_grant(grantor: groups(:top_layer), role_types: [Group::TopGroup::Leader])
      create_grant(grantor: groups(:top_group), role_types: [Group::TopGroup::Leader])

      people = eligibility.people.to_a
      expect(people.count { |p| p.id == top_leader.id }).to eq(1)
    end

    it "returns Person.none when definition has no grants" do
      expect(eligibility.people).to eq(Person.none)
    end

    it "handles multiple grants with different role types" do
      create_grant(grantor: groups(:top_group), role_types: [Group::TopGroup::Leader])
      create_grant(grantor: groups(:bottom_layer_one), role_types: [Group::BottomLayer::Member])

      result = eligibility.people
      expect(result).to include(top_leader)
      expect(result).to include(bottom_member)
    end
  end

  describe "#member?" do
    it "returns true when person has matching active role" do
      create_grant(grantor: groups(:top_group), role_types: [Group::TopGroup::Leader])

      expect(eligibility.member?(top_leader)).to be true
    end

    it "returns false when person has no matching role" do
      create_grant(grantor: groups(:top_group), role_types: [Group::TopGroup::Secretary])

      expect(eligibility.member?(top_leader)).to be false
    end

    it "returns false for person with ended role" do
      create_grant(grantor: groups(:top_group), role_types: [Group::TopGroup::Member])

      person = Fabricate(:person)
      create_role(person: person, group: groups(:top_group), type: Group::TopGroup::Member,
        start_on: 2.months.ago.to_date, end_on: 1.day.ago.to_date)

      expect(eligibility.member?(person)).to be false
    end

    it "returns false for person with archived role" do
      create_grant(grantor: groups(:top_group), role_types: [Group::TopGroup::Member])

      person = Fabricate(:person)
      create_role(person: person, group: groups(:top_group), type: Group::TopGroup::Member,
        archived_at: 1.day.ago)

      expect(eligibility.member?(person)).to be false
    end
  end

  describe "#matching_roles" do
    it "returns active matching roles for person" do
      create_grant(grantor: groups(:top_group), role_types: [Group::TopGroup::Leader])

      roles = eligibility.matching_roles(top_leader)
      expect(roles).to include(roles(:top_leader))
    end

    it "excludes archived roles" do
      create_grant(grantor: groups(:top_group), role_types: [Group::TopGroup::Member])

      person = Fabricate(:person)
      archived_role = create_role(person: person, group: groups(:top_group),
        type: Group::TopGroup::Member, archived_at: 1.day.ago)

      expect(eligibility.matching_roles(person)).not_to include(archived_role)
    end

    it "excludes ended roles" do
      create_grant(grantor: groups(:top_group), role_types: [Group::TopGroup::Member])

      person = Fabricate(:person)
      ended_role = create_role(person: person, group: groups(:top_group),
        type: Group::TopGroup::Member,
        start_on: 2.months.ago.to_date, end_on: 1.day.ago.to_date)

      expect(eligibility.matching_roles(person)).not_to include(ended_role)
    end

    it "returns roles matching across multiple grants" do
      create_grant(grantor: groups(:top_group), role_types: [Group::TopGroup::Leader, Group::TopGroup::Member])

      person = Fabricate(:person)
      member_role = create_role(person: person, group: groups(:top_group), type: Group::TopGroup::Member)

      expect(eligibility.matching_roles(person)).to include(member_role)
    end

    it "returns empty relation when no grants exist" do
      expect(eligibility.matching_roles(top_leader)).to be_empty
    end
  end

  describe "#matching_roles_including_ended" do
    it "includes ended roles" do
      create_grant(grantor: groups(:top_group), role_types: [Group::TopGroup::Member])

      person = Fabricate(:person)
      ended_role = create_role(person: person, group: groups(:top_group),
        type: Group::TopGroup::Member,
        start_on: 2.months.ago.to_date, end_on: 1.day.ago.to_date)

      expect(eligibility.matching_roles_including_ended(person)).to include(ended_role)
    end

    it "includes archived roles" do
      create_grant(grantor: groups(:top_group), role_types: [Group::TopGroup::Member])

      person = Fabricate(:person)
      archived_role = create_role(person: person, group: groups(:top_group),
        type: Group::TopGroup::Member, archived_at: 1.day.ago)

      expect(eligibility.matching_roles_including_ended(person)).to include(archived_role)
    end

    it "includes active roles" do
      create_grant(grantor: groups(:top_group), role_types: [Group::TopGroup::Leader])

      expect(eligibility.matching_roles_including_ended(top_leader)).to include(roles(:top_leader))
    end

    it "excludes roles from outside the grant subtree" do
      create_grant(grantor: groups(:bottom_layer_one), role_types: [Group::BottomGroup::Member])

      person = Fabricate(:person)
      outside_role = create_role(person: person, group: groups(:bottom_group_two_one),
        type: Group::BottomGroup::Member,
        start_on: 2.months.ago.to_date, end_on: 1.day.ago.to_date)

      expect(eligibility.matching_roles_including_ended(person)).not_to include(outside_role)
    end

    it "returns empty relation when no grants exist" do
      expect(eligibility.matching_roles_including_ended(top_leader)).to be_empty
    end
  end

  describe ".definitions_for" do
    it "returns definitions matching person's active roles" do
      create_grant(grantor: groups(:top_group), role_types: [Group::TopGroup::Leader])

      expect(described_class.definitions_for(top_leader)).to include(definition)
    end

    it "excludes definitions where role type does not match" do
      create_grant(grantor: groups(:top_group), role_types: [Group::TopGroup::Secretary])

      expect(described_class.definitions_for(top_leader)).not_to include(definition)
    end

    it "matches when grantor group encompasses the role's group" do
      # Grant on top_layer (lft:1, rgt:18) should match role in top_group (lft:14, rgt:15)
      create_grant(grantor: groups(:top_layer), role_types: [Group::TopGroup::Leader])

      expect(described_class.definitions_for(top_leader)).to include(definition)
    end

    it "does not match when role group is outside grantor subtree" do
      # Grant on bottom_layer_one should NOT match top_leader's role in top_group
      create_grant(grantor: groups(:bottom_layer_one), role_types: [Group::TopGroup::Leader])

      expect(described_class.definitions_for(top_leader)).not_to include(definition)
    end

    it "returns distinct definitions even with multiple matching grants" do
      create_grant(grantor: groups(:top_layer), role_types: [Group::TopGroup::Leader])
      create_grant(grantor: groups(:top_group), role_types: [Group::TopGroup::Leader])

      result = described_class.definitions_for(top_leader)
      expect(result.count { |d| d.id == definition.id }).to eq(1)
    end

    it "returns empty relation for person with no active roles" do
      person = Fabricate(:person)

      expect(described_class.definitions_for(person)).to be_empty
    end

    it "excludes definitions for ended roles" do
      create_grant(grantor: groups(:top_group), role_types: [Group::TopGroup::Member])

      person = Fabricate(:person)
      create_role(person: person, group: groups(:top_group), type: Group::TopGroup::Member,
        start_on: 2.months.ago.to_date, end_on: 1.day.ago.to_date)

      expect(described_class.definitions_for(person)).not_to include(definition)
    end
  end

  describe ".group_definitions_for" do
    it "delegates to same logic as definitions_for" do
      create_grant(grantor: groups(:top_group), role_types: [Group::TopGroup::Leader])

      expect(described_class.group_definitions_for(top_leader)).to include(definition)
    end
  end

  describe ".affected_pass_memberships" do
    it "finds pass_memberships affected by a role change" do
      create_grant(grantor: groups(:top_group), role_types: [Group::TopGroup::Leader])
      membership = Fabricate(:pass_membership,
        person: top_leader, pass_definition: definition, state: :eligible)

      role = roles(:top_leader)
      result = described_class.affected_pass_memberships(top_leader, role: role)
      expect(result).to include(membership)
    end

    it "finds memberships when grantor encompasses the role's group" do
      create_grant(grantor: groups(:top_layer), role_types: [Group::TopGroup::Leader])
      membership = Fabricate(:pass_membership,
        person: top_leader, pass_definition: definition, state: :eligible)

      role = roles(:top_leader)
      result = described_class.affected_pass_memberships(top_leader, role: role)
      expect(result).to include(membership)
    end

    it "excludes memberships with non-matching role type" do
      create_grant(grantor: groups(:top_group), role_types: [Group::TopGroup::Secretary])
      membership = Fabricate(:pass_membership,
        person: top_leader, pass_definition: definition, state: :eligible)

      role = roles(:top_leader) # Leader, not Secretary
      result = described_class.affected_pass_memberships(top_leader, role: role)
      expect(result).not_to include(membership)
    end

    it "excludes memberships when role's group is outside grantor subtree" do
      create_grant(grantor: groups(:bottom_layer_one), role_types: [Group::TopGroup::Leader])
      membership = Fabricate(:pass_membership,
        person: top_leader, pass_definition: definition, state: :eligible)

      role = roles(:top_leader) # in top_group, outside bottom_layer_one
      result = described_class.affected_pass_memberships(top_leader, role: role)
      expect(result).not_to include(membership)
    end

    it "returns empty when person has no pass_memberships" do
      create_grant(grantor: groups(:top_group), role_types: [Group::TopGroup::Leader])

      role = roles(:top_leader)
      result = described_class.affected_pass_memberships(top_leader, role: role)
      expect(result).to be_empty
    end
  end
end
