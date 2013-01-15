class RenameJsDescToJsLabelInEventKinds < ActiveRecord::Migration
  def up
    rename_column :event_kinds, :j_s_description, :j_s_label
  end

  def down
  end
end
