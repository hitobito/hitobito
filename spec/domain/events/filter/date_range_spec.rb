# frozen_string_literal: true

#  Copyright (c) 2021, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Events::Filter::DateRange do
  let(:person) { people(:top_leader) }
  let(:options) { { kind_used: true } }

  let(:scope) { Events::FilteredList.new(person, {}, options).base_scope }

  subject(:filter) { described_class.new(person, params, options, scope) }

  let(:sql) { filter.to_scope.to_sql }
  let(:where_condition) { sql.sub(/.*(WHERE.*)$/, '\1') }

  def a_year_after(date)
    Date.parse(date).advance(years: 1)
  end

  context 'generally, it' do
    let(:params) do
      {
        filter: {
          since: '01.01.1970',
          until: '19.01.2038'
        }
      }
    end

    it 'produces a scope that checks for dates' do
      expect(where_condition).to match('event_dates.start_at')
      expect(where_condition).to match('event_dates.finish_at')

      expect(where_condition).to match(
        /.*start_at <= .* AND .*finish_at >= .* OR .*start_at <= .* AND .*start_at >= .*/
      )
    end

    context 'has assumptions' do
      it 'mentions event_dates' do
        expect(sql).to match('event_dates')
      end

      it 'there is a WHERE condition' do
        expect(where_condition).to match(/^WHERE/)
      end

      it 'converts dates to YYYY-MM-DD' do
        expect(where_condition).to match(/1970-01-01/)
        expect(where_condition).to match(/2038-01-19/)

        expect(where_condition).to_not match(/01.01.1970/)
        expect(where_condition).to_not match(/19.01.2038/)
      end
    end
  end

  context 'without dates, it' do
    let(:today) { Time.zone.now.to_date.strftime('%F') }
    let(:params) { {} }

    it 'uses the default of a year from now' do
      expect(where_condition).to match(/event_dates.start_at <= '#{a_year_after today}'/)
      expect(where_condition).to match(/event_dates.finish_at >= '#{today}'/)
      expect(where_condition).to match(/event_dates.start_at <= '#{a_year_after today}'/)
      expect(where_condition).to match(/event_dates.start_at >= '#{today}'/)
    end
  end

  context 'with only a since date, it' do
    let(:today) { '2021-04-14' }
    let(:params) do
      {
        filter: {
          since: today
        }
      }
    end

    it 'uses the default of a year from now' do
      expect(where_condition).to match(/event_dates.start_at <= '#{a_year_after today}'/)
      expect(where_condition).to match(/event_dates.finish_at >= '#{today}'/)
      expect(where_condition).to match(/event_dates.start_at <= '#{a_year_after today}'/)
      expect(where_condition).to match(/event_dates.start_at >= '#{today}'/)
    end
  end

  context 'with only an until date, it' do
    let(:today) { Time.zone.now.to_date.strftime('%F') }
    let(:limit) { '2038-01-19' }
    let(:params) do
      {
        filter: {
          until: limit
        }
      }
    end

    it 'uses the default of a year from now' do
      expect(where_condition).to match(/event_dates.start_at <= '#{limit}'/)
      expect(where_condition).to match(/event_dates.finish_at >= '#{today}'/)
      expect(where_condition).to match(/event_dates.start_at <= '#{limit}'/)
      expect(where_condition).to match(/event_dates.start_at >= '#{today}'/)
    end
  end

  context 'with both since and until dates, it' do
    let(:params) do
      {
        filter: {
          since: '13.04.2021',
          until: '26.08.2021'
        }
      }
    end

    it 'produces a scope that checks for the requested date-range' do
      expect(where_condition).to match(/event_dates.start_at <= '2021-08-26'/)
      expect(where_condition).to match(/event_dates.finish_at >= '2021-04-13'/)
      expect(where_condition).to match(/event_dates.start_at <= '2021-08-26'/)
      expect(where_condition).to match(/event_dates.start_at >= '2021-04-13'/)
    end
  end

end
