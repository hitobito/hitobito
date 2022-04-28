# frozen_string_literal: true

#  Copyright (c) 2021, Die Mitte Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Address::FullTextSearch do

  let(:person) { people(:bottom_member) }

  [SearchStrategies::Sphinx, SearchStrategies::Sql].each do |strategy|
    context "with #{strategy}" do
      before do
        allow_any_instance_of(strategy).to receive(:query_addresses)
          .and_return(Address.where(id: addresses(:bs_bern)))
      end

      it 'finds typeahead results from street query without street number' do
        bs_bern = addresses(:bs_bern)
        query = 'lpstra'

        search = Address::FullTextSearch.new(query, strategy.new(person, query, ''))
        results = search.typeahead_results

        expect(results.size).to eq(1)

        result = results.first

        expect(result[:id]).to eq(bs_bern.id)
        expect(result[:label]).to eq(bs_bern.to_s)
        expect(result[:town]).to eq(bs_bern.town)
        expect(result[:zip_code]).to eq(bs_bern.zip_code)
        expect(result[:street]).to eq(bs_bern.street_short)
        expect(result[:state]).to eq(bs_bern.state)
      end

      it 'finds typeahead results from street query with street number' do
        bs_bern = addresses(:bs_bern)
        query = 'lpstra 4'

        search = Address::FullTextSearch.new(query, strategy.new(person, query, ''))
        results = search.typeahead_results

        expect(results.size).to eq(2)

        first_result = results.first

        labels = results.map { |r| r[:label] }
        numbers = results.map { |r| r[:number] }

        expect(first_result[:id]).to eq(bs_bern.id)
        expect(first_result[:town]).to eq(bs_bern.town)
        expect(first_result[:zip_code]).to eq(bs_bern.zip_code)
        expect(first_result[:street]).to eq(bs_bern.street_short)
        expect(first_result[:state]).to eq(bs_bern.state)
        numbers.each do |number|
          expect(labels).to include(bs_bern.label_with_number(number))
        end
      end

      it 'finds typeahead results from street query with street number with a lowercase letter' do
        bs_bern = addresses(:bs_bern)
        query = 'lpstra 5a'

        search = Address::FullTextSearch.new(query, strategy.new(person, query, ''))
        results = search.typeahead_results

        # we found one street/number combination
        expect(results.size).to eq(1)

        # we found the right street
        expect(results.first[:id]).to eq(bs_bern.id)

        # we detected the right number
        expect(results.map { |r| r[:number] }).to include('5a')

        # with the right label
        expect(results.map { |r| r[:label] }).to include(bs_bern.label_with_number('5a'))
      end

      it 'finds typeahead results from street query with street number with a uppercase letter' do
        bs_bern = addresses(:bs_bern)
        query = 'lpstra 6B'

        search = Address::FullTextSearch.new(query, strategy.new(person, query, ''))
        results = search.typeahead_results

        # we found one street/number combination
        expect(results.size).to eq(1)

        # we found the right street
        expect(results.first[:id]).to eq(bs_bern.id)

        # we detected the right number
        expect(results.map { |r| r[:number] }).to include('6B')

        # with the right label
        expect(results.map { |r| r[:label] }).to include(bs_bern.label_with_number('6B'))
      end

      it 'finds typeahead results from street query with street number and town' do
        bs_bern = addresses(:bs_bern)
        query = 'Belpstra 6B be'

        search = Address::FullTextSearch.new(query, strategy.new(person, query, ''))
        results = search.typeahead_results

        # we found one street/number combination
        expect(results.size).to eq(1)

        # we found the right street
        expect(results.first[:id]).to eq(bs_bern.id)

        # we detected the right number
        expect(results.map { |r| r[:number] }).to include('6B')

        # with the right label
        expect(results.map { |r| r[:label] }).to eq(['Belpstrasse 6B Bern'])
      end
    end
  end
end
