class AddEventKindQualificationKindGrouping < ActiveRecord::Migration[4.2]
  def change
    add_column :event_kind_qualification_kinds, :grouping, :integer
  end
end
