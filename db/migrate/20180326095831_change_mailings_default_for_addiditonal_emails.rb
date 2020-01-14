class ChangeMailingsDefaultForAddiditonalEmails < ActiveRecord::Migration[4.2]
  def up
    change_column_default :additional_emails, :mailings, false
  end

  def down
    change_column_default :additional_emails, :mailings, true
  end
end
