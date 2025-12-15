# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

module QueryHelpers
  IGNORED_QUERIES = %w[SCHEMA TRANSACTION].freeze

  # Tracks and verifies database query counts in tests.
  #
  # Usage:
  #
  # 1. Check total query count (backward compatible):
  #   expect_query_count do
  #     MyModel.where(active: true).to_a
  #   end.to eq 1
  #
  # 2. Verify specific query counts by query name:
  #   expect_query_count("MyModel Load": 1, "Person Load": 3) do
  #     MyModel.first.to_s
  #   end
  #
  # Query names correspond to the model names for Load queries, or
  # operation types like "Create", "Update", "Destroy", etc.
  # SCHEMA and TRANSACTION queries are automatically ignored.
  def expect_query_count(**expected_counts, &block)
    counts = Hash.new(0)
    total_count = [0]

    callback = build_query_callback(counts, total_count)

    ActiveSupport::Notifications.subscribed(callback, "sql.active_record", &block)

    if expected_counts.any?
      verify_expected_counts(counts, expected_counts)
    else
      expect(total_count[0])
    end
  end

  private

  def build_query_callback(counts, total_count)
    lambda do |*args|
      query = args.last
      query_name = query[:name]

      unless IGNORED_QUERIES.include?(query_name)
        counts[query_name] += 1
        total_count[0] += 1
      end
    end
  end

  def verify_expected_counts(counts, expected_counts)
    aggregate_failures do
      check_query_names(counts, expected_counts)
      check_query_counts(counts, expected_counts)
    end
  end

  def check_query_names(counts, expected_counts)
    expected_names = expected_counts.keys.map(&:to_s).sort
    actual_names = counts.keys.sort

    expected_list = expected_names.join(", ")
    actual_list = actual_names.join(", ")

    expect(actual_names).to eq(expected_names),
      "Query name mismatch!\n" \
      "  Expected query names: [#{expected_list}]\n" \
      "  Actual query names: [#{actual_list}]\n" \
      "  Actual counts: #{counts.inspect}"
  end

  def check_query_counts(counts, expected_counts)
    expected_counts.each do |query_name, expected_count|
      actual_count = counts[query_name.to_s]
      expect(actual_count).to eq(expected_count),
        "Expected #{expected_count} for '#{query_name}', got #{actual_count}"
    end
  end
end
