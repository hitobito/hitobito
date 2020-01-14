class ScopeArticleNumberUniqnessOnGroup < ActiveRecord::Migration[4.2]
  def change
    remove_index :invoice_articles, column: :number, unique: true
    add_index :invoice_articles, [:number, :group_id], unique: true
  end
end
