class AddLayerAndBelowToServiceTokens < ActiveRecord::Migration[6.1]
  def change
    add_column :service_tokens, :layer_and_below_read, :boolean, null: false, default: false
  end
end
