# frozen_string_literal: true

#  Copyright (c) 2021, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Events::Filter::PlacesAvailable do
  let(:person) { people(:top_leader) }
  let(:options) { { kind_used: true } }

  let(:scope) { Events::FilteredList.new(person, {}, options).base_scope }

  subject(:filter) { described_class.new(person, params, options, scope) }

  let(:sql) { filter.to_scope.to_sql }
  let(:where_condition) { sql.sub(/.*(WHERE.*)$/, '\1') }

  let!(:unlimited_course) do
    Fabricate(:course, name: 'unlimited', maximum_participants: nil, participant_count: 23)
  end

  let!(:filled_course) do
    Fabricate(:course, name: 'full', maximum_participants: 23, participant_count: 23)
  end


  context 'has assumptions' do
    let(:params) { {} } # dummy, not needed

    it 'there are 3 courses' do
      expect(Event::Course.count).to eq 3
    end
  end

  context 'with the request to show available places, it' do
    let(:params) do
      {
        filter: {
          places_available: 1
        }
      }
    end

    it 'checks the maximum_participants' do
      expect(where_condition)
        .to match(/COALESCE\(maximum_participants, 0\) = 0/)
    end

    it 'compares the participant_count to the maximum_participants' do
      expect(where_condition)
        .to match('participant_count < maximum_participants')
    end

    it 'does not include the filled_course in the results' do
      expect(subject.to_scope.to_a).to_not include filled_course
    end

    it 'does include the unlimited_course in the results' do
      expect(subject.to_scope.to_a).to include unlimited_course
    end

    it 'shows only 2 results' do
      expect(subject.to_scope.to_a).to have(2).entries
    end
  end

  context 'with no request to limit to available places, it' do
    let(:params) do
      {
        filter: {
          places_available: 0
        }
      }
    end

    it 'does not check maximum_participants' do
      expect(where_condition).to_not match('maximum_participants')
    end

    it 'does not check participant_count' do
      expect(where_condition).to_not match('participant_count')
    end

    it 'does include the filled_course in the results' do
      expect(subject.to_scope.to_a).to include filled_course
    end

    it 'does include the unlimited_course in the results' do
      expect(subject.to_scope.to_a).to include unlimited_course
    end

    it 'shows all 3 courses' do
      expect(subject.to_scope.to_a).to have(3).entries
    end
  end
end
