class ChangeMailingsDefaultForAddiditonalEmails < ActiveRecord::Migration
  def change
  	change_column_default :additional_emails, :mailings, :false
  end
end
