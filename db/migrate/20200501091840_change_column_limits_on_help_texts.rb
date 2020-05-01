class ChangeColumnLimitsOnHelpTexts < ActiveRecord::Migration[6.0]
  def change
    reversible do |dirs|
      dirs.up do # reduce size so the index can handle utf-8
        change_column :help_texts, :controller, :string, limit: 100
        change_column :help_texts, :model,      :string, limit: 100
        change_column :help_texts, :kind,       :string, limit: 100
        change_column :help_texts, :name,       :string, limit: 100
      end

      dirs.down do # revert back to defaults
        change_column :help_texts, :controller, :string
        change_column :help_texts, :model,      :string
        change_column :help_texts, :kind,       :string
        change_column :help_texts, :name,       :string
      end
    end
  end
end
