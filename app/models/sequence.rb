# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Sequence
  def self.current_value(sequence_name)
    sql = "SELECT currval('#{ActiveRecord::Base.connection.quote_table_name(sequence_name)}')"
    ActiveRecord::Base.connection.select_value(sql)
  rescue ActiveRecord::StatementInvalid
    select("MAX(household_key::integer) AS max_household_key").take.max_household_key
  end

  def self.increment!(sequence_name)
    sql = ActiveRecord::Base.send(:sanitize_sql_array, ["SELECT nextval(?)", sequence_name])
    ActiveRecord::Base.connection.select_value(sql)
  end
end
