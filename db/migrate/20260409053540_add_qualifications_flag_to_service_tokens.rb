class AddQualificationsFlagToServiceTokens < ActiveRecord::Migration[8.0]
  def change
    add_column(:service_tokens, :qualifications, :boolean, default: false, null: false)
  end
end
