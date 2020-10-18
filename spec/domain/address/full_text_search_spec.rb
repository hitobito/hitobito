# frozen_string_literal: true

require 'spec_helper'

describe Address::FullTextSearch do

  let(:person)   { people(:bottom_member) }

    [SearchStrategies::Sphinx, SearchStrategies::Sql].each do |strategy|
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
    end
end
