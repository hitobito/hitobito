# frozen_string_literal: true

#  Copyright (c) 2021, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Events::Filter::State do
  let(:person) { people(:top_leader) }
  let(:options) { { kind_used: true } }

  let(:scope) { Events::FilteredList.new(person, {}, options).base_scope }

  subject(:filter) { described_class.new(person, params, options, scope) }

  let(:sql) { filter.to_scope.to_sql }
  let(:where_condition) { sql.sub(/.*(WHERE.*)$/, '\1') }

  before do
    Event::Course.possible_states = %w(
      created confirmed application_open application_closed
      assignment_closed canceled completed closed
    )
  end

  after do
    Event::Course.possible_states = []
  end


  context 'has assumptions' do
    let(:params) { {} } # dummy, not needed

    it 'knows possible states' do
      expect(subject.send(:possible_states)).to match_array(Event::Course.possible_states)
    end

    it 'blørbaël is not a known state' do
      expect(subject.send(:possible_states)).to_not include('blørbaël')
    end
  end

  context 'with a possible state, it' do
    let(:params) do
      {
        filter: {
          states: ['confirmed']
        }
      }
    end

    it 'passes the value verbatim' do
      expect(where_condition).to match("`state` = 'confirmed'")
    end
  end

  context 'with a not possible state, it' do
    let(:params) do
      {
        filter: {
          states: ['blørbaël']
        }
      }
    end

    it 'does not filter by state' do
      expect(where_condition).to_not match('state')
    end

    it 'does not pass on the wrong state' do
      expect(where_condition).to_not match('blørbaël')
    end
  end
end
