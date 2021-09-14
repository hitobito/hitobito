class AddPpPostAndShippingMethodToMessages < ActiveRecord::Migration[6.0]
  def change
    add_column :messages, :pp_post, :string
    add_column :messages, :shipping_method, :string, default: 'own'
  end
end
