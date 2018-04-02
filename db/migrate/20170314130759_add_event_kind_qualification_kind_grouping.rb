class AddEventKindQualificationKindGrouping < ActiveRecord::Migration
  def change
    add_column :event_kind_qualification_kinds, :grouping, :integer
  end
end
