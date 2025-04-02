module QueryMatchers
  # Make the ignored list easily accessible, perhaps move to a central config if used elsewhere
  IGNORED_QUERIES = %w[SCHEMA TRANSACTION].freeze

  RSpec::Matchers.define :make_database_queries do |expected_count|
    supports_block_expectations # Crucial for expect { ... }.to syntax

    match do |block_to_test|
      # Guard clause for incorrect usage
      unless block_to_test.is_a?(Proc)
        raise ArgumentError, "You must pass a block to make_database_queries"
      end

      # @actual_count will store the number of queries executed
      @actual_count = 0 # Reset count for each test run

      callback = lambda do |*args|
        query = args.last # Notification payload is the last argument
        # Uncomment for debugging:
        # puts "[SQL DEBUG] Name: #{query[:name]}, SQL: #{query[:sql]}"
        unless IGNORED_QUERIES.include?(query[:name])
          @actual_count += 1
        end
      end

      # Subscribe to SQL notifications only during the block execution
      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        block_to_test.call # Execute the proc passed to expect { ... }
      end

      # The matcher passes if the actual count matches the expected count
      @actual_count == expected_count
    end

    failure_message do |_actual_block|
      "expected the block to make #{expected_count} database queries, but it made #{@actual_count}"
    end

    failure_message_when_negated do |_actual_block|
      "expected the block not to make #{expected_count} database queries, but it did"
    end

    # description used in RSpec output, e.g., "should make X database queries"
    description do
      "make #{expected_count} database queries"
    end
  end
end
