class ChangeSubjectLengthOnMessage < ActiveRecord::Migration[6.1]
  def change
    change_column :messages, :subject, :string, limit: 998
  end
end
