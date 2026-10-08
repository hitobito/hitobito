# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe AbilityDsl::Condition do
  let(:a) { {contact_data_visible: true} }
  let(:b) { {roles: {group_id: 1}} }
  let(:c) { {email: "foo@example.com"} }

  describe ".any_of" do
    it "drops nil operands" do
      expect(described_class.any_of(nil, a)).to eq(a)
      expect(described_class.any_of(nil, nil)).to be_nil
    end

    it "is unconditional if any operand is unconditional" do
      expect(described_class.any_of(a, {})).to eq({})
    end

    it "flattens nested any_of" do
      condition = described_class.any_of(a, described_class.any_of(b, c))
      expect(condition.operands).to eq([a, b, c])
    end
  end

  describe ".all_of" do
    it "drops nil operands" do
      expect(described_class.all_of(nil, a)).to eq(a)
      expect(described_class.all_of(nil)).to be_nil
    end

    it "drops unconditional operands" do
      expect(described_class.all_of({}, a)).to eq(a)
      expect(described_class.all_of({}, {})).to eq({})
    end

    it "merges hashes with disjoint keys" do
      expect(described_class.all_of(a, b, c)).to eq(a.merge(b).merge(c))
    end

    it "keeps hashes with the same keys separate" do
      other = {roles: {type: "Foo"}}
      condition = described_class.all_of(a, b, other)
      expect(condition).to be_a(AbilityDsl::Condition::AllOf)
      expect(condition.operands).to eq([a.merge(b), other])
    end
  end

  describe ".none_of" do
    it "keeps nil" do
      expect(described_class.none_of(nil)).to be_nil
    end

    it "never matches for an unconditional operand" do
      expect(described_class.none_of({})).to eq(id: [])
    end

    it "negates any of the operands" do
      condition = described_class.none_of(a, b)
      expect(condition).to be_a(AbilityDsl::Condition::NoneOf)
      expect(condition.operand.operands).to eq([a, b])
    end

    it "removes double negation" do
      expect(described_class.none_of(described_class.none_of(a))).to eq(a)
    end
  end

  context "evaluation" do
    let(:ability) { Object.new.extend(CanCan::Ability) }
    let(:top_group) { groups(:top_group) }
    let(:bottom_layer) { groups(:bottom_layer_one) }

    before do
      Fabricate(Group::TopGroup::Member.sti_name, group: top_group,
        person: Fabricate(:person, contact_data_visible: true))
      Fabricate(Group::BottomLayer::Member.sti_name, group: bottom_layer,
        person: Fabricate(:person, contact_data_visible: true))
      Fabricate(Group::BottomLayer::Leader.sti_name, group: bottom_layer, person: people(:top_leader))
      Fabricate(Group::BottomGroup::Member.sti_name, group: groups(:bottom_group_one_one))
      Fabricate(:person)
    end

    def leaves
      [
        {contact_data_visible: true},
        {roles: {group_id: top_group.id}},
        {roles: {group: {layer_group_id: bottom_layer.id}}},
        {roles: {type: Group::BottomLayer::Member.sti_name}},
        {roles: {group: {lft: [bottom_layer.lft..bottom_layer.rgt]}}},
        {id: Person.where(email: people(:top_leader).email).select(:id)},
        {id: [people(:bottom_member).id]},
        {}
      ]
    end

    def random_condition(random, depth = 0)
      return leaves.sample(random: random) if depth > 2 || random.rand < 0.3

      operands = Array.new(random.rand(1..3)) { random_condition(random, depth + 1) }
      case random.rand(3)
      when 0 then described_class.any_of(*operands)
      when 1 then described_class.all_of(*operands)
      else described_class.none_of(operands.first)
      end
    end

    def emit(condition)
      if condition.is_a?(AbilityDsl::Condition)
        ability.can :show, Person, id: condition
      else
        ability.can :show, Person, condition
      end
    end

    it "lists the same people as it matches in memory for random conditions" do
      random = Random.new(RSpec.configuration.seed)
      people = Person.all.to_a

      50.times do
        condition = random_condition(random)
        ability.instance_variable_set(:@rules, [])
        ability.instance_variable_set(:@rules_index, nil)
        emit(condition)

        expected = people.select { |p| ability.can?(:show, p) }.map(&:id)
        listed = Person.accessible_by(ability, :show).pluck(:id)
        expect(listed).to match_array(expected), "for #{condition.inspect}"
      end
    end

    it "matches unsaved records in memory" do
      emit(described_class.any_of(described_class.none_of(contact_data_visible: true),
        {roles: {group_id: top_group.id}}))

      expect(ability.can?(:show, Person.new(contact_data_visible: false))).to eq(true)
      expect(ability.can?(:show, Person.new(contact_data_visible: true))).to eq(false)
      expect(ability.can?(:show,
        Person.new(contact_data_visible: true, roles: [Role.new(group: top_group)]))).to eq(true)
    end

    it "compiles a negated association to an anti subquery" do
      emit(described_class.none_of(roles: {group: {layer_group_id: bottom_layer.id}}))

      expect(Person.accessible_by(ability, :show).to_sql).to include("NOT IN")
      expect(ability.can?(:show, people(:top_leader))).to eq(false)
      expect(ability.can?(:show, people(:bottom_member))).to eq(false)
      expect(ability.can?(:show, people(:root))).to eq(true)
    end
  end
end
