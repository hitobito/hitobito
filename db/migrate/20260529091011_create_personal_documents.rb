class CreatePersonalDocuments < ActiveRecord::Migration[8.0]
  def change
    create_table :personal_documents do |t|
      t.belongs_to :person, foreign_key: true, null: false
      t.belongs_to :personal_document_label, foreign_key: false
      t.belongs_to :author, foreign_key: { to_table: :people }, null: false

      t.timestamps
    end
  end
end
