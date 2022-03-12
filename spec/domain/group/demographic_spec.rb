# encoding: utf-8
# frozen_string_literal: true

#  Copyright (c) 2022, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Group::Demographic do
  let(:year_now) { 2022 }
  let(:leader) { people(:top_leader) }
  let(:layer) { groups(:top_layer) }
  let(:demographic) { Group::Demographic.new(layer, year_now) }
  let(:age_groups) { demographic.age_groups }
  let(:total_count) { demographic.total_count }

  context 'single layer, single person' do
    before { leader.update(birthday: Date.parse('1991-01-01')) }

    it '#age_groups' do
      expect(age_groups.length).to eq(1)

      age_group = age_groups.first
      expect(age_group.year).to eq(1991)
      expect(age_group.age).to eq(31)
      expect(age_group.count).to eq(1)
      expect(age_group.relative_count).to eq(1)
    end

    it '#total_count' do
      expect(total_count).to eq(1)
    end
  end

  context 'with subgroups, multiple people' do
    let(:group) { groups(:top_group) }
    let!(:group_members) do
      3.times do
        person = Fabricate(:person, birthday: Date.parse('1992-02-01'))
        Fabricate(Group::TopGroup::Leader.name, group: group, person: person)
      end
    end

    before do
      leader.update(birthday: Date.parse('1991-01-01'))
    end

    it '#age_groups' do
      expect(age_groups).to eq(
        [
          Group::Demographic::AgeGroup.new(year: 1991, age: 31, count: 1, relative_count: 0.25),
          Group::Demographic::AgeGroup.new(year: 1992, age: 30, count: 3, relative_count: 0.75)
        ]
      )
    end

    it '#total_count' do
      expect(total_count).to eq(4)
    end

    context 'with unknown ages' do
      before { leader.update(birthday: nil) }

      it '#age_groups' do
        expect(age_groups).to eq(
          [
            Group::Demographic::AgeGroup.new(year: 1992, age: 30, count: 3, relative_count: 0.75),
            Group::Demographic::AgeGroup.new(year: nil, age: nil, count: 1, relative_count: 0.25)
          ]
        )
      end
    end

  end
end
