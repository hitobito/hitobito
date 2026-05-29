class CreatePersonalDocumentLabels < ActiveRecord::Migration[8.0]
  def change
    create_table :personal_document_labels do |t|
      t.string :name, null: false

      t.timestamps
    end
  end
end
