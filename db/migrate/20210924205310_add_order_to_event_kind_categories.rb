class AddOrderToEventKindCategories < ActiveRecord::Migration[6.0]
  def change
    add_column :event_kind_categories, :order, :int
  end
end
