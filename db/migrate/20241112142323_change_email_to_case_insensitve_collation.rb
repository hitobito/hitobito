# frozen_string_literal: true

class ChangeEmailToCaseInsensitveCollation < ActiveRecord::Migration[6.1]
  def list_of_email_columns
    [
      [:additional_emails, :email],
      [:groups, :email],
      [:groups, :self_registration_notification_email],
      [:invoice_configs, :email],
      [:invoices, :recipient_email],
      [:mail_logs, :mail_from],
      [:mailing_lists, :additional_sender],
      [:message_recipients, :email],
      [:people, :email],
      [:people, :unconfirmed_email],
    ]
  end

  def list_of_affected_search_columns
    [:additional_emails, :people, :groups]
  end

  def list_of_possibly_duplicated_tuples
    list = []

    mr_datasource = "message_recipients WHERE email IS NOT NULL GROUP BY (message_id, person_id, LOWER(email)) HAVING count(*) > 1"
    list << [
      'message_recipients',
      "SELECT max(count) - 1 FROM (SELECT count(*) AS count FROM #{mr_datasource})",
      "DELETE FROM message_recipients WHERE id IN (SELECT min(id) FROM #{mr_datasource})"
    ]
  end

  def up
    say_with_time "creating collation" do
      execute "CREATE COLLATION IF NOT EXISTS case_insensitive_emails (provider = icu, locale = 'und-u-ka-noignore-ks-level2', deterministic = false);"
    end

    list_of_affected_search_columns.each do |table|
      remove_column table, :search_column, if_exists: true
    end

    say_with_time "cleaning some data if needed" do
      list_of_possibly_duplicated_tuples.each do |table, count_query, cleanup_query|
        needed_runs = connection.select_value(count_query).to_i
        next if needed_runs == 0

        say "Need #{needed_runs} passes to clean #{table}"
        needed_runs.times { execute(cleanup_query) }
      end
    end

    say_with_time "setting the case-insensitive collation" do
      list_of_email_columns.each do |table, column|
        execute "ALTER TABLE #{table} ALTER COLUMN #{column} SET DATA TYPE varchar COLLATE case_insensitive_emails;"
      end
    end
  end

  def down
    list_of_affected_search_columns.each do |table|
      remove_column table, :search_column, if_exists: true
    end

    say_with_time "setting the default collation" do
      list_of_email_columns.each do |table, column|
        execute "ALTER TABLE #{table} ALTER COLUMN #{column} SET DATA TYPE varchar;"
      end
    end

    say_with_time "dropping collation" do
      execute "DROP COLLATION case_insensitive_emails;"
    end
  end
end
