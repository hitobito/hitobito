class AllowNullPersonInMessageRecipients < ActiveRecord::Migration[6.0]
  def change
    change_column_null :message_recipients, :person_id, true
  end
end
