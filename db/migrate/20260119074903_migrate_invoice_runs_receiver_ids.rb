#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class MigrateInvoiceRunsReceiverIds < ActiveRecord::Migration[8.0]
  def up
    add_column :people_filters, :visible, :boolean, default: false
    # Only visible filters require names
    change_column :people_filters, :name, :string, null: true

    # Set all exisiting presisted people_filters to be visible
    execute <<~SQL
      UPDATE people_filters
      SET visible = TRUE;
    SQL

    # Migrate all receiver_type "group" invoice_runs to people_filter
    execute <<-SQL
      ALTER TABLE people_filters ADD COLUMN temp_invoice_run_id INTEGER;

      INSERT INTO people_filters (group_id, range, temp_invoice_run_id)
      SELECT receiver_id, 'group', id
      FROM invoice_runs
      WHERE receiver_type = 'Group';

      UPDATE invoice_runs
      SET receiver_id = people_filters.id, receiver_type = 'PeopleFilter'
      FROM people_filters
      WHERE people_filters.temp_invoice_run_id = invoice_runs.id;

      ALTER TABLE people_filters DROP COLUMN temp_invoice_run_id
    SQL

    # Migrate all recipient_ids from invoice_runs into people_filters
    # We can assume all receivers are currently a Person (type group doesn't exist yet)
    # The feature to have groups as receivers has not been implemented yet
    # So the 'type' of the receiver isn't something else than 'Person' in the database yet.
    execute <<-SQL
      ALTER TABLE people_filters ADD COLUMN temp_invoice_run_id INTEGER;

      WITH source_data AS (
        SELECT
          id AS invoice_run_id,
          group_id,
          matches[1]::bigint AS person_id
        FROM
          invoice_runs,
          LATERAL regexp_matches(receivers, ':id: ([0-9]+)', 'g') AS matches
        WHERE receivers IS NOT NULL
      ), receiver_ids_yaml AS (
        SELECT
            invoice_run_id,
            group_id,
            string_agg('      - ' || person_id, E'\n') AS filter_chain
        FROM source_data
        GROUP BY invoice_run_id, group_id
      )

      INSERT INTO people_filters (group_id, range, filter_chain, temp_invoice_run_id)
      SELECT
          group_id,
          'deep',
          concat(
              '---' , E'\n',
              'attributes:', E'\n',
              '  ''0'':', E'\n',
              '    key: id', E'\n',
              '    constraint: include', E'\n',
              '    value:', E'\n',
              filter_chain
          ),
          invoice_run_id
      FROM receiver_ids_yaml;

      UPDATE invoice_runs
      SET receiver_id = people_filters.id, receiver_type = 'PeopleFilter'
      FROM people_filters
      WHERE people_filters.temp_invoice_run_id = invoice_runs.id;

      ALTER TABLE people_filters DROP COLUMN temp_invoice_run_id;
    SQL

    rename_column :invoice_runs, :receiver_id, :recipient_source_id
    rename_column :invoice_runs, :receiver_type, :recipient_source_type

    remove_column :invoice_runs, :receivers
  end

  def down
    remove_column :people_filters, :visible

    rename_column :invoice_runs, :recipient_source_id, :receiver_id
    rename_column :invoice_runs, :recipient_source_type, :receiver_type

    add_column :invoice_runs, :receivers, :text
  end
end
