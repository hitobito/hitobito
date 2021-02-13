# frozen_string_literal: true

#  Copyright (c) 2012-2020, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

class Address::FullTextSearch
  attr_reader :query, :search_strategy

  ADDRESS_WITH_NUMBER_REGEX = /^.*[^\d](\d+[A-Z]?$)/

  def initialize(query, search_strategy)
    @query = query
    @search_strategy = search_strategy
  end

  def typeahead_results
    addresses = with_query { search_strategy.query_addresses }

    typeahead_entries(addresses)
  end

  def results
    addresses = with_query { search_strategy.query_addresses }

    addresses = addresses_with_numbers(addresses).map(&:first) if query_ends_with_number?

    addresses
  end

  private

  def typeahead_entries(addresses)
    results = typeahead_results_with_numbers(addresses) if query_ends_with_number?

    results ||= addresses.map { |a| a.as_typeahead }

    results
  end

  def typeahead_results_with_numbers(addresses)
    addresses_with_numbers(addresses).map do |address, number|
      address.as_typeahead_with_number(number)
    end
  end

  def addresses_with_numbers(addresses)
    addresses.flat_map do |address|
      address.numbers.map do |number|
        [address, number] if number.to_s.include? street_number_from_query
      end.compact
    end
  end

  def with_query
    query.to_s.size >= 2 ? yield : []
  end

  def query_ends_with_number?
    query.match?(ADDRESS_WITH_NUMBER_REGEX)
  end

  def street_number_from_query
    query.match(ADDRESS_WITH_NUMBER_REGEX)[1]
  end
end
