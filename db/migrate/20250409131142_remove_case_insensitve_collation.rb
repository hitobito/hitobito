class RemoveCaseInsensitveCollation < ActiveRecord::Migration[7.1]
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

  def up
    list_of_affected_search_columns.each do |table|
      remove_column table, :search_column, if_exists: true
    end

    say_with_time "removing the collation from tables" do
      list_of_email_columns.each do |table, column|
        execute "ALTER TABLE #{table} ALTER COLUMN #{column} SET DATA TYPE varchar;"
      end
    end

    say_with_time "dropping collation" do
      execute "DROP COLLATION case_insensitive_emails;"
    end
  end
end
