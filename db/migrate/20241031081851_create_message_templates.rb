class CreateMessageTemplates < ActiveRecord::Migration[6.1]
  def change
    create_table :message_templates do |t|
      t.references :templated, polymorphic: true
      t.string :title, null: false
      t.text :body

      t.timestamps
    end
  end
end
