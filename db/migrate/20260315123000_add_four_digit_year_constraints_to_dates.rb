#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddFourDigitYearConstraintsToDates < ActiveRecord::Migration[8.0]
  def up
    # ---- Cap existing out-of-range data before adding constraints ----

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

    # ---- Add check constraints enforcing 1900..9999 ----

    execute <<~SQL
      ALTER TABLE roles
      ADD CONSTRAINT chk_roles_start_on_year_range
      CHECK (start_on IS NULL OR (EXTRACT(YEAR FROM start_on) >= 1900 AND EXTRACT(YEAR FROM start_on) <= 9999));
    SQL

    execute <<~SQL
      ALTER TABLE roles
      ADD CONSTRAINT chk_roles_end_on_year_range
      CHECK (end_on IS NULL OR (EXTRACT(YEAR FROM end_on) >= 1900 AND EXTRACT(YEAR FROM end_on) <= 9999));
    SQL

    execute <<~SQL
      ALTER TABLE people
      ADD CONSTRAINT chk_people_birthday_year_range
      CHECK (birthday IS NULL OR (EXTRACT(YEAR FROM birthday) >= 1900 AND EXTRACT(YEAR FROM birthday) <= 9999));
    SQL

    execute <<~SQL
      ALTER TABLE event_dates
      ADD CONSTRAINT chk_event_dates_start_at_year_range
      CHECK (start_at IS NULL OR (EXTRACT(YEAR FROM start_at) >= 1900 AND EXTRACT(YEAR FROM start_at) <= 9999));
    SQL

    execute <<~SQL
      ALTER TABLE event_dates
      ADD CONSTRAINT chk_event_dates_finish_at_year_range
      CHECK (finish_at IS NULL OR (EXTRACT(YEAR FROM finish_at) >= 1900 AND EXTRACT(YEAR FROM finish_at) <= 9999));
    SQL

    execute <<~SQL
      ALTER TABLE qualifications
      ADD CONSTRAINT chk_qualifications_start_at_year_range
      CHECK (EXTRACT(YEAR FROM start_at) >= 1900 AND EXTRACT(YEAR FROM start_at) <= 9999);
    SQL

    execute <<~SQL
      ALTER TABLE qualifications
      ADD CONSTRAINT chk_qualifications_finish_at_year_range
      CHECK (finish_at IS NULL OR (EXTRACT(YEAR FROM finish_at) >= 1900 AND EXTRACT(YEAR FROM finish_at) <= 9999));
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE qualifications DROP CONSTRAINT IF EXISTS chk_qualifications_finish_at_year_range;
    SQL
    execute <<~SQL
      ALTER TABLE qualifications DROP CONSTRAINT IF EXISTS chk_qualifications_start_at_year_range;
    SQL
    execute <<~SQL
      ALTER TABLE event_dates DROP CONSTRAINT IF EXISTS chk_event_dates_finish_at_year_range;
    SQL
    execute <<~SQL
      ALTER TABLE event_dates DROP CONSTRAINT IF EXISTS chk_event_dates_start_at_year_range;
    SQL
    execute <<~SQL
      ALTER TABLE people DROP CONSTRAINT IF EXISTS chk_people_birthday_year_range;
    SQL
    execute <<~SQL
      ALTER TABLE roles DROP CONSTRAINT IF EXISTS chk_roles_end_on_year_range;
    SQL
    execute <<~SQL
      ALTER TABLE roles DROP CONSTRAINT IF EXISTS chk_roles_start_on_year_range;
    SQL
  end
end
