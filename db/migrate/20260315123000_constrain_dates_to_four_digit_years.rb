#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class ConstrainDatesToFourDigitYears < ActiveRecord::Migration[8.0]
  def up
    # roles.start_on / end_on
    execute <<~SQL
      UPDATE roles SET start_on = '9999-12-31'
      WHERE start_on IS NOT NULL AND EXTRACT(YEAR FROM start_on) > 9999;
    SQL
    execute <<~SQL
      UPDATE roles SET start_on = '1900-01-01'
      WHERE start_on IS NOT NULL AND EXTRACT(YEAR FROM start_on) < 1900;
    SQL
    execute <<~SQL
      UPDATE roles SET end_on = '9999-12-31'
      WHERE end_on IS NOT NULL AND EXTRACT(YEAR FROM end_on) > 9999;
    SQL
    execute <<~SQL
      UPDATE roles SET end_on = '1900-01-01'
      WHERE end_on IS NOT NULL AND EXTRACT(YEAR FROM end_on) < 1900;
    SQL

    # people.birthday
    execute <<~SQL
      UPDATE people SET birthday = '9999-12-31'
      WHERE birthday IS NOT NULL AND EXTRACT(YEAR FROM birthday) > 9999;
    SQL
    execute <<~SQL
      UPDATE people SET birthday = '1900-01-01'
      WHERE birthday IS NOT NULL AND EXTRACT(YEAR FROM birthday) < 1900;
    SQL

    # event_dates.start_at / finish_at
    execute <<~SQL
      UPDATE event_dates SET start_at = '9999-12-31'
      WHERE start_at IS NOT NULL AND EXTRACT(YEAR FROM start_at) > 9999;
    SQL
    execute <<~SQL
      UPDATE event_dates SET start_at = '1900-01-01'
      WHERE start_at IS NOT NULL AND EXTRACT(YEAR FROM start_at) < 1900;
    SQL
    execute <<~SQL
      UPDATE event_dates SET finish_at = '9999-12-31'
      WHERE finish_at IS NOT NULL AND EXTRACT(YEAR FROM finish_at) > 9999;
    SQL
    execute <<~SQL
      UPDATE event_dates SET finish_at = '1900-01-01'
      WHERE finish_at IS NOT NULL AND EXTRACT(YEAR FROM finish_at) < 1900;
    SQL

    # qualifications.start_at / finish_at
    execute <<~SQL
      UPDATE qualifications SET start_at = '9999-12-31'
      WHERE EXTRACT(YEAR FROM start_at) > 9999;
    SQL
    execute <<~SQL
      UPDATE qualifications SET start_at = '1900-01-01'
      WHERE EXTRACT(YEAR FROM start_at) < 1900;
    SQL
    execute <<~SQL
      UPDATE qualifications SET finish_at = '9999-12-31'
      WHERE finish_at IS NOT NULL AND EXTRACT(YEAR FROM finish_at) > 9999;
    SQL
    execute <<~SQL
      UPDATE qualifications SET finish_at = '1900-01-01'
      WHERE finish_at IS NOT NULL AND EXTRACT(YEAR FROM finish_at) < 1900;
    SQL
  end

  def down
  end
end
