class AddDisplayOnlyOwnLabelFormatsToPeople < ActiveRecord::Migration
  def change
    add_column :people, :display_only_own_label_formats, :boolean, default: false
  end
end
