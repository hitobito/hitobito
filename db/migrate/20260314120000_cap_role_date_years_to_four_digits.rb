#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class CapRoleDateYearsToFourDigits < ActiveRecord::Migration[8.0]
  def up
    # Cap start_on year above 9999 to 9999-12-31
    execute <<~SQL
      UPDATE roles
      SET start_on = '9999-12-31'
      WHERE start_on IS NOT NULL
        AND EXTRACT(YEAR FROM start_on) > 9999;
    SQL

    # Cap start_on year below 1000 to 1900-01-01
    execute <<~SQL
      UPDATE roles
      SET start_on = '1900-01-01'
      WHERE start_on IS NOT NULL
        AND EXTRACT(YEAR FROM start_on) < 1000;
    SQL

    # Cap end_on year above 9999 to 9999-12-31
    execute <<~SQL
      UPDATE roles
      SET end_on = '9999-12-31'
      WHERE end_on IS NOT NULL
        AND EXTRACT(YEAR FROM end_on) > 9999;
    SQL

    # Cap end_on year below 1000 to 1900-01-01
    execute <<~SQL
      UPDATE roles
      SET end_on = '1900-01-01'
      WHERE end_on IS NOT NULL
        AND EXTRACT(YEAR FROM end_on) < 1000;
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
