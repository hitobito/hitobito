# frozen_string_literal: true

#  Copyright (c) 2021, Die Mitte Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Address::FullTextSearch do
  let(:person) { people(:bottom_member) }

  before do
    allow(SearchStrategies::AddressSearch).to receive(:search_fulltext)
      .and_return(Address.where(id: addresses(:bs_bern)))
  end

  it "finds typeahead results from street query without street number" do
    bs_bern = addresses(:bs_muri)
    query = "Belpstra"

    search = Address::FullTextSearch.new(query)
    results = search.typeahead_results

    expect(results.size).to eq(2)

    result = results.first

    expect(result[:id]).to eq(bs_bern.id)
    expect(result[:label]).to eq(bs_bern.to_s)
    expect(result[:town]).to eq(bs_bern.town)
    expect(result[:zip_code]).to eq(bs_bern.zip_code)
    expect(result[:street]).to eq(bs_bern.street_short)
    expect(result[:state]).to eq(bs_bern.state)
  end

  it "finds typeahead results from street query with street number" do
    bs_bern = addresses(:bs_bern)
    query = "Belpstra 4"

    search = Address::FullTextSearch.new(query)
    results = search.typeahead_results

    expect(results.size).to eq(2)

    first_result = results.first

    labels = results.pluck(:label)
    numbers = results.pluck(:number)

    expect(first_result[:id]).to eq(bs_bern.id)
    expect(first_result[:town]).to eq(bs_bern.town)
    expect(first_result[:zip_code]).to eq(bs_bern.zip_code)
    expect(first_result[:street]).to eq(bs_bern.street_short)
    expect(first_result[:state]).to eq(bs_bern.state)
    numbers.each do |number|
      expect(labels).to include(bs_bern.label_with_number(number))
    end
  end

  it "finds typeahead results from street query with street number with a lowercase letter" do
    bs_bern = addresses(:bs_bern)
    query = "Belpstra 5a"

    search = Address::FullTextSearch.new(query)
    results = search.typeahead_results

    # we found one street/number combination
    expect(results.size).to eq(1)

    # we found the right street
    expect(results.first[:id]).to eq(bs_bern.id)

    # we detected the right number
    expect(results.pluck(:number)).to include("5a")

    # with the right label
    expect(results.pluck(:label)).to include(bs_bern.label_with_number("5a"))
  end

  it "finds typeahead results from street query with street number with a uppercase letter" do
    bs_bern = addresses(:bs_bern)
    query = "Belpstra 6B"

    search = Address::FullTextSearch.new(query)
    results = search.typeahead_results

    # we found one street/number combination
    expect(results.size).to eq(1)

    # we found the right street
    expect(results.first[:id]).to eq(bs_bern.id)

    # we detected the right number
    expect(results.pluck(:number)).to include("6B")

    # with the right label
    expect(results.pluck(:label)).to include(bs_bern.label_with_number("6B"))
  end

  it "finds typeahead results from street query with street number and town" do
    bs_bern = addresses(:bs_bern)
    query = "Belpstra 6B be"

    search = Address::FullTextSearch.new(query)
    results = search.typeahead_results

    # we found one street/number combination
    expect(results.size).to eq(1)

    # we found the right street
    expect(results.first[:id]).to eq(bs_bern.id)

    # we detected the right number
    expect(results.pluck(:number)).to include("6B")

    # with the right label
    expect(results.pluck(:label)).to eq(["Belpstrasse 6B 3007 Bern"])
  end
end
