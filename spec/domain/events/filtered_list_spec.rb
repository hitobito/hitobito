# frozen_string_literal: true

#  Copyright (c) 2021, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Events::FilteredList do
  let(:person) { people(:top_leader) }
  let(:params) { {} }
  let(:options) { { kind_used: true } }

  subject do
    described_class.new(person, params, options)
  end

  it 'has a base-scope' do
    expect(subject.base_scope).to be_a ActiveRecord::Relation
    expect(subject.base_scope.klass).to eq Event::Course
  end

  it 'has filter_scopes' do
    expect(subject.filter_scopes).to match_array [
      Events::Filter::DateRange,
      Events::Filter::CourseKindCategory,
      Events::Filter::State,
      :list
    ]
  end

  context 'without event-kinds, to' do
    let(:options) { { kind_used: false } }

    it 'does not use filter for CourseKindCategory' do
      expect(subject.filter_scopes).to_not include(Events::Filter::CourseKindCategory)
    end
  end
end
