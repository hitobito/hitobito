class AddFilterChainToMailingLists < ActiveRecord::Migration[6.1]
  def change
    add_column :mailing_lists, :filter_chain, :text, null: true
  end
end
