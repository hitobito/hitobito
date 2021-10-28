class RemoveHeadingFromMessage < ActiveRecord::Migration[6.0]
  def change
    remove_column :messages, :heading
  end
end
