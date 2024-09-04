# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

module QueryHelpers
  IGNORED_QUERIES = %w[SCHEMA TRANSACTION].freeze

  def expect_query_count(&)
    count = 0
    callback = lambda do |*args|
      query = args.last
      # puts "#{query[:name]}: #{query[:sql]}"
      count += 1 unless IGNORED_QUERIES.include?(query[:name])
    end
    ActiveSupport::Notifications.subscribed(callback, "sql.active_record", &)
    expect(count)
  end
end
