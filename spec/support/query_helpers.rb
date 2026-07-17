# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

module QueryHelpers
  IGNORED_QUERIES = %w[SCHEMA TRANSACTION].freeze

  # Callable object for counting queries
  QueryCounter = Struct.new(:queries, :count_per_query) do
    def initialize(queries = [], count_per_query = Hash.new(0)) = super

    delegate :count, to: :queries

    def call(*args)
      query = args.last
      query_name = query[:name]

      return if IGNORED_QUERIES.include?(query_name)

      count_per_query[query_name] += 1
      query_details = {name: query_name, sql: query[:sql]}

      detect_location(query_details)
      detect_trigger(query_details)

      queries << query_details
    end

    def count = queries.size

    private

    # Detects where the query originated (app code or spec)
    def detect_location(query_details)
      app_lines = caller.select { |line| line.include?("/app/") }

      if app_lines.empty?
        detect_spec_location(query_details)
      else
        detect_app_location(query_details, app_lines)
      end
    end

    # Sets location to spec file when query is triggered from test code
    def detect_spec_location(query_details)
      spec_line = caller.find { |line|
        line.include?("/spec/") && !line.include?("/query_helpers.rb")
      }
      query_details[:location] = spec_line || "unknown location"
      query_details[:from_spec] = true
    end

    # Sets location to app file when query is triggered from application code
    def detect_app_location(query_details, app_lines)
      query_details[:location] = app_lines.first
      query_details[:all_app_locations] = app_lines if app_lines.size > 1
    end

    # Extracts the method that triggered the query (e.g., to_a, first, pluck)
    def detect_trigger(query_details)
      trigger_line = caller.find { |line| relevant_trigger_line?(line) } or return

      trigger_method = trigger_line[/`([^']+)'$/, 1]
      query_details[:trigger] = trigger_method if trigger_method
    end

    # Checks if a caller line contains a relevant trigger method
    def relevant_trigger_line?(line)
      return false if line.include?("/query_helpers.rb")
      return false if line.include?("<internal:")
      return false unless line.match?(/`([^']+)'/)

      method_name = line[/`([^']+)'$/, 1]
      return false if method_name.nil?
      return false if internal_method?(method_name)

      true
    end

    # Checks if a method name is an internal/RSpec method to skip
    def internal_method?(method_name)
      method_name.start_with?("block in", "_") ||
        %w[finish run call].include?(method_name)
    end
  end

  # Count queries executed in a block
  def self.count_queries(&block)
    QueryCounter.new.tap do |counter|
      ActiveSupport::Notifications.subscribed(counter, "sql.active_record", &block)
    end
  end

  # RSpec matcher for query count testing
  #
  # Usage:
  #   # Check that at least 1 query was made
  #   expect { code }.to make.db_queries
  #
  #   # Check absolute total number of queries
  #   expect { code }.to make(7).db_queries
  #
  #   # Check specific query counts (other queries are allowed)
  #   expect { code }.to make.db_queries.with("Invoice Load" => 1, "Person Load" => 2)
  #
  #   # Check both total AND specific query counts
  #   expect { code }.to make(7).db_queries.with("Invoice Load" => 1, "Person Load" => 2)
  #
  # Negated usage:
  #   # Check that NO queries were made
  #   expect { code }.not_to make.db_queries
  #
  #   # Check that NOT exactly n queries were made
  #   expect { code }.not_to make(7).db_queries
  #
  #   # Check that specific query counts do NOT match
  #   expect { code }.not_to make.db_queries.with("Invoice Load" => 1)
  #
  # Note:
  #   - make.db_queries (no count) verifies at least 1 query was made
  #   - make(n) verifies the ABSOLUTE total number of queries (exactly n queries, no more, no less)
  #   - with() verifies counts for SPECIFIC query types only (other queries are allowed)
  #   - Combining both ensures the total is n AND includes the specified queries
  RSpec::Matchers.define :make do |expected_count = nil|
    supports_block_expectations

    chain :db_queries do
      @db_queries = true
    end

    chain :db_query do
      @db_queries = true
    end

    chain :with do |expected_query_counts|
      @expected_query_counts = expected_query_counts
    end

    match do |block|
      return false unless @db_queries

      @expected_count = expected_count
      @counter = QueryHelpers.count_queries(&block)

      # If neither count nor specific queries specified, check for at least 1 query
      if @expected_count.nil? && !@expected_query_counts&.present?
        @counter.count > 0
      else
        count_matches && queries_match
      end
    end

    failure_message do
      # Handle case where @counter is nil (e.g., when using nested expects)
      unless @counter
        return "Query counter was not initialized. " \
               "This usually happens when using nested expect statements. " \
               "Use: result = nil; expect { result = code }.to make(n).db_queries; expect(result)..."
      end

      message = if @expected_query_counts
        expected_list = @expected_query_counts.map { |k, v| "#{k}: #{v}" }.join(", ")
        # Show specified queries first
        actual_specified = @expected_query_counts.map do |k, v|
          actual_count = @counter.count_per_query[k.to_s] || 0
          "#{k}: #{actual_count}"
        end.join(", ")

        msg = "expected queries: {#{expected_list}}"
        msg += " (total: #{@expected_count})" if @expected_count
        msg += ", but got: {#{actual_specified}}"
        msg += " (total: #{@counter.count})" if @expected_count

        # List other queries if any
        specified_keys = @expected_query_counts.keys.map(&:to_s)
        other_queries = @counter.count_per_query.except(*specified_keys)
        if other_queries.any?
          other_list = other_queries.map { |k, v| "#{k}: #{v}" }.join(", ")
          msg += "\nalso counted following queries: {#{other_list}}"
        end

        msg
      elsif @expected_count
        query_word = (@expected_count == 1) ? "query" : "queries"
        "expected block to make #{@expected_count} database #{query_word}, " \
          "but made #{@counter.count}"
      else
        # No count or with() specified - checking for at least 1 query
        "expected block to make at least 1 database query, but made 0"
      end
      message += format_queries(@counter.queries) if @counter.queries&.any?
      message
    end

    failure_message_when_negated do
      if @expected_query_counts
        msg = "expected block not to make " \
              "{#{@expected_query_counts.map { |k, v| "#{k}: #{v}" }.join(", ")}}"
        msg += " (total: #{@expected_count})" if @expected_count
        msg + ", but it did"
      elsif @expected_count
        query_word = (@expected_count == 1) ? "query" : "queries"
        "expected block not to make #{@expected_count} database #{query_word}, but it did"
      else
        "expected block not to make any database queries, but it did"
      end
    end

    def count_matches
      return true if @expected_count.nil?

      @counter.count == @expected_count
    end

    def queries_match
      return true if @expected_query_counts.nil?

      # Check only the specified queries, allow others
      @expected_query_counts.all? do |query_name, expected_count|
        @counter.count_per_query[query_name.to_s] == expected_count
      end
    end

    def format_queries(queries)
      "\n\nExecuted queries (#{queries.size}):\n" +
        queries.map.with_index do |q, i|
          parts = ["  #{i + 1}. [#{q[:name]}] #{q[:sql]}"]

          # Add trigger info if available
          if q[:trigger]
            source = q[:from_spec] ? "spec" : "app"
            parts << "     triggered by: #{q[:trigger]} (from #{source})"
          end

          # Add location info if available
          if q[:location]
            parts << "     at #{q[:location]}"
          end

          parts.join("\n")
        end.join("\n")
    end
  end
end
