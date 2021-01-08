class AddSubscriptionTags < ActiveRecord::Migration[6.0]
  def up
    create_table :subscription_tags do |t|
      t.boolean :excluded
    end

    add_reference :subscription_tags, :subscription, foreign_key: true, type: :integer
    add_reference :subscription_tags, :tag, foreign_key: true, type: :integer
  end

  def down
    drop_table :subscription_tags
  end
end

