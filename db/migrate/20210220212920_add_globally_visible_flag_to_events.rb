class AddGloballyVisibleFlagToEvents < ActiveRecord::Migration[6.0]
  def change
    # intentionally nullable and without default
    add_column :events, :globally_visible, :boolean
  end
end
