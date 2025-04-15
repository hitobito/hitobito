class RemoveCaseInsensitveCollation < ActiveRecord::Migration[7.1]
  def up
    list_of_affected_search_columns.each do |table|
      remove_column table, :search_column, if_exists: true
    end

    say_with_time "removing the collation from known tables" do
      list_of_email_columns.each do |table, column|
        execute "ALTER TABLE #{table} ALTER COLUMN #{column} SET DATA TYPE varchar;"
        execute "UPDATE #{table} SET #{column} = LOWER(#{column})"
      end
    end

    drop_collation
  end

  def down

    say_with_time "creating collation" do
      execute "CREATE COLLATION IF NOT EXISTS case_insensitive_emails (provider = icu, locale = 'und-u-ka-noignore-ks-level2', deterministic = false);"
    end

    say_with_time "setting the case-insensitive collation" do
      list_of_email_columns.each do |table, column|
        execute "ALTER TABLE #{table} ALTER COLUMN #{column} SET DATA TYPE varchar COLLATE case_insensitive_emails;"
      end
    end
  end

  private

  def drop_collation
    res = execute "select count(*) from information_schema.columns WHERE collation_name = 'case_insensitive_emails'"
    if res[0]['count'].zero?
      say_with_time "trying to drop the collation" do
        execute "DROP COLLATION case_insensitive_emails;"
      end
    end
  end

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
end
