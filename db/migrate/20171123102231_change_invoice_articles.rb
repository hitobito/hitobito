class ChangeInvoiceArticles < ActiveRecord::Migration[4.2]
  def change
    # Workaround because SQLite cannot add new column with null false
    add_column(:invoice_articles, :group_id, :integer, index: true)
    change_column(:invoice_articles, :group_id, :integer, null: false, index: true)
    
    rename_column(:invoice_articles, :net_price, :unit_cost)

    reversible do |dir|
      dir.up do
        change_column(:invoice_articles, :description, :text)
      end

      dir.down do
        change_column(:invoice_articles, :description, :string)
      end
    end
  end
end
