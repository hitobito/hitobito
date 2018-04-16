class ChangeMailingsDefaultForAddiditonalEmails < ActiveRecord::Migration
  def up
    change_column_default :additional_emails, :mailings, false
  end

  def down
    change_column_default :additional_emails, :mailings, true
  end
end
