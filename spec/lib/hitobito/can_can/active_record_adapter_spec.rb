# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Hitobito::CanCan::ActiveRecordAdapter do
  let(:ability) { Object.new.extend(CanCan::Ability) }
  let(:top_leader) { people(:top_leader) }
  let(:bottom_member) { people(:bottom_member) }
  let!(:bottom_group_member) do
    Fabricate(Group::BottomGroup::Member.sti_name, group: groups(:bottom_group_one_one)).person
  end
  let(:all_people) { Person.all.to_a }

  def expect_consistent(action, model_class = Person, records = all_people)
    listed = model_class.accessible_by(ability, action).to_a
    expect(listed.size).to eq(listed.uniq.size)
    expect(listed).to match_array(records.select { |r| ability.can?(action, r) })
    listed
  end

  it "is used for all active record classes" do
    expect(CanCan::ModelAdapters::AbstractAdapter.adapter_class(Person)).to eq(described_class)
    expect(CanCan::ModelAdapters::AbstractAdapter.adapter_class(Group::BottomLayer))
      .to eq(described_class)
  end

  it "uses the subquery strategy" do
    expect(CanCan.accessible_by_strategy).to eq(:subquery)
  end

  context "with relation values" do
    before { ability.can :show, Person, id: Person.where(id: top_leader.id).select(:id) }

    it "matches persisted records in memory and in sql" do
      expect(ability.can?(:show, top_leader)).to eq(true)
      expect(ability.can?(:show, bottom_member)).to eq(false)
      expect(expect_consistent(:show)).to eq([top_leader])
    end

    it "does not match new records" do
      expect(ability.can?(:show, Person.new)).to eq(false)
    end

    it "matches the selected column of the relation" do
      ability.can :update, Person, id: Role.where(group: groups(:bottom_layer_one)).select(:person_id)

      expect(ability.can?(:update, bottom_member)).to eq(true)
      expect(ability.can?(:update, top_leader)).to eq(false)
      expect(expect_consistent(:update)).to eq([bottom_member])
    end

    it "memoizes the result per value" do
      expect { 3.times { ability.can?(:show, top_leader) } }.to make(1).db_queries
    end
  end

  context "with arrays of ranges" do
    let(:bottom_layer_one) { groups(:bottom_layer_one) }
    let(:bottom_layer_two) { groups(:bottom_layer_two) }
    let(:ranges) { [bottom_layer_one, bottom_layer_two].map { |g| g.lft..g.rgt } }

    it "matches if any range covers the value" do
      ability.can :show, Group, lft: ranges

      expect(ability.can?(:show, groups(:bottom_group_one_one))).to eq(true)
      expect(ability.can?(:show, groups(:bottom_group_two_one))).to eq(true)
      expect(ability.can?(:show, groups(:top_group))).to eq(false)
      expect_consistent(:show, Group, Group.all.to_a)
    end

    it "matches plain values and nil in the same array" do
      ability.can :show, Group, archived_at: [nil, 1.year.ago..]

      expect(ability.can?(:show, groups(:top_group))).to eq(true)
      expect_consistent(:show, Group, Group.all.to_a)
    end

    it "matches through has_many associations" do
      ability.can :show, Person, roles: {group: {lft: ranges}}

      expect(ability.can?(:show, bottom_member)).to eq(true)
      expect(ability.can?(:show, bottom_group_member)).to eq(true)
      expect(ability.can?(:show, top_leader)).to eq(false)
      expect_consistent(:show)
    end
  end

  it "reads columns that were not selected from the database" do
    ability.can :show, Person, contact_data_visible: true

    expect(ability.can?(:show, Person.only_public_data.find(top_leader.id))).to eq(true)
    expect(ability.can?(:show, Person.only_public_data.find(bottom_member.id))).to eq(false)
  end

  context "with has_many associations" do
    before { ability.can :show, Person, roles: {group_id: groups(:top_group).id} }

    it "ignores unsaved records of saved subjects like sql does" do
      bottom_member.roles.build(group: groups(:top_group))

      expect(ability.can?(:show, bottom_member)).to eq(false)
    end

    it "matches saved subjects without records for nil conditions" do
      ability.can :index, Person, roles: {id: nil}

      expect(ability.can?(:index, Fabricate(:person))).to eq(true)
      expect(ability.can?(:index, bottom_member)).to eq(false)
    end

    it "matches unsaved records of new subjects" do
      person = Person.new(roles: [Role.new(group: groups(:top_group))])

      expect(ability.can?(:show, person)).to eq(true)
    end
  end

  context "with has_many joins" do
    before do
      Fabricate(Group::BottomGroup::Leader.sti_name, group: groups(:bottom_group_one_one),
        person: bottom_member)
      ability.can :show, Person, roles: {group_id: groups(:bottom_group_one_one).id}
      ability.can :show, Person, roles: {group: {layer_group_id: groups(:bottom_layer_one).id}}
    end

    it "lists each person once" do
      expect(expect_consistent(:show)).to match_array([bottom_member, bottom_group_member])
    end

    it "can be combined with a custom select and an order on joined columns" do
      people = Person.only_public_data.joins(roles: :group).order("groups.name")
        .accessible_by(ability, :show)
      expect(people.map(&:id).uniq).to match_array([bottom_member.id, bottom_group_member.id])
    end
  end
end
