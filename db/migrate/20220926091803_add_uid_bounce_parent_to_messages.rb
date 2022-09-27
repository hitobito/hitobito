# frozen_string_literal: true

class AddUidBounceParentToMessages < ActiveRecord::Migration[6.1]

  def change
    add_column :messages, :uid, :string, null: true, index: true
    add_column :messages, :bounce_parent_id, :integer, null: true, index: true
  end

end
