class CreatePayees < ActiveRecord::Migration[6.1]
  def change
    create_table :payees do |t|
      t.belongs_to :person, null: true
      t.belongs_to :payment, null: false

      t.string :person_name
      t.text :person_address

      t.timestamps
    end
  end
end
