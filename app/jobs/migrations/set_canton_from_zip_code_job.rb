# frozen_string_literal: true

#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Migrations
  class SetCantonFromZipCodeJob < BaseJob
    def perform
      return unless Countries.default == "ch"

      ActiveRecord::Base.connection.execute(<<~SQL)
        UPDATE people
        SET canton = locations.canton,
            country = COALESCE(NULLIF(people.country, ''), 'CH')
        FROM locations
        WHERE locations.zip_code = people.zip_code
          AND people.canton IS NULL
          AND people.zip_code IS NOT NULL
          AND people.zip_code <> ''
          AND (people.country IS NULL OR people.country = '' OR TRIM(UPPER(people.country)) = 'CH')
      SQL
    end
  end
end
