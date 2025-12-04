#  Copyright (c) 2018, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Person::Filter::List do
  let(:person) { people(:top_leader) }
  let(:group) { groups(:top_group) }
  let(:filter) { PeopleFilter.new(name: "name") }

  subject(:list) { described_class.new(group, person, filter) }

  context "top group" do
    it "empty filter lists members of group" do
      expect(group.people).to include(person)

      expect(list.all_count).to eq 1
      expect(list.entries.to_a).to have(1).items
      expect(list.entries.collect(&:id)).to eq [person.id]
    end
  end

  context "group with 23 people" do
    let(:group) { groups(:bottom_group_one_two) }
    let(:person) { Fabricate(Group::BottomGroup::Leader.sti_name.to_sym, group: group).person }

    before do
      # 1 leader (the person) and 22 members form the group of 23 people
      22.times { Fabricate(Group::BottomGroup::Member.sti_name.to_sym, group: group) }
    end

    it "has 23 people in group without filters" do
      expect(list.all_count).to eq 23
      expect(list.entries).to have(23).items
    end

    context "filtered by id" do
      let(:filter) do
        PeopleFilter.new(name: "id-limited").to_params.merge({
          ids: group.people.limit(5).pluck(:id).join(",")
        })
      end

      it "has assumptions" do
        expect(list.instance_variable_get(:@ids)).to be_an Array
        ids = list.instance_variable_get(:@ids)

        expect(ids).to have(5).items

        actual_ids = group.people.pluck(:id).map(&:to_s)

        ids.all? do |id|
          expect(actual_ids).to include(id)
        end
      end

      it "lists 5 people" do
        expect(list.entries).to have(5).items
      end
    end

    context "filtered by all" do
      let(:filter) do
        PeopleFilter.new(name: "all-limited").to_params.merge({
          ids: "all"
        })
      end

      it "lists 23 people" do
        expect(list.entries).to have(23).items
      end
    end
  end

  context "bottom group" do
    let(:group) { groups(:bottom_group_one_one) }

    it "empty filter returns empty list" do
      expect(list.all_count).to eq 0
      expect(list.entries.to_a).to be_empty
    end

    context "with future role" do
      before do
        Fabricate(
          group.role_types.first.sti_name.to_sym,
          person: person,
          group: group,
          start_on: 1.day.from_now
        )
      end

      it "does not include future role" do
        expect(list.all_count).to eq 0
        expect(list.entries.to_a).to be_empty
      end
    end
  end

  context "archived groups" do
    let(:person) { people(:root) }

    before do
      group.archive!
      expect(group.archived_at).to_not be_nil
    end

    it "empty filter with range deep does not list people from archived groups" do
      expect(list.all_count).to eq 0
      expect(list.entries.to_a).to have(0).items
    end

    it "empty filter with range layer does not list people from archived groups" do
      expect(list.all_count).to eq 0
      expect(list.entries.to_a).to have(0).items
    end

    it "empty filter with empty range does not list people from archived groups" do
      expect(list.all_count).to eq 0
      expect(list.entries.to_a).to have(0).items
    end
  end
end
