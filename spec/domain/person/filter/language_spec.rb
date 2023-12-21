# frozen_string_literal: true

#  Copyright (c) 2012-2023, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Person::Filter::Language do

  let(:user)         { people(:top_leader) }
  let(:group)        { groups(:top_group) }
  let(:range)         { 'deep' }
  let(:filter_attrs) { { allowed_values: languages } }
  let(:list_filter) do
    Person::Filter::List.new(
      group,
      user,
      range: range,
      filters: { language: filter_attrs }
    )
  end
  let!(:members) do
    [:en, :de, :fr, :it].to_h do |language|
      person = Fabricate(:person, language: language)
      member = Fabricate(Group::TopGroup::Member.name.to_sym, group: group, person: person)
      [language, person]
    end
  end
  subject(:entries) { list_filter.entries }

  context 'no filter' do
    let(:filter_attrs) { {} }

    it 'contains all existing members' do
      expect(entries.size).to eq(list_filter.all_count)
    end
  end

  context 'with all languages allowed' do
    let(:filter_attrs) { { allowed_values: members.keys } }

    it { is_expected.to include(*members.values) }
  end

  context 'with no languages allowed' do
    let(:filter_attrs) { { allowed_values: [] } }

    it 'contains all existing members' do
      expect(entries.size).to eq(list_filter.all_count)
      is_expected.to include(*members.values)
    end
  end

  context 'with some languages allowed' do
    let(:filter_attrs) { { allowed_values: [:fr, :it] } }

    it { is_expected.to include(*members.slice(:fr, :it).values) }
    it { is_expected.not_to include(*members.slice(:en, :de).values) }
  end
end
