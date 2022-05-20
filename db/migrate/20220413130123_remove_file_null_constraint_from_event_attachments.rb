class RemoveFileNullConstraintFromEventAttachments < ActiveRecord::Migration[6.1]
  def change
    change_column_null(:event_attachments, :file, true) # allow null-values
  end
end
