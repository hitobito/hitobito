class AddInvoiceModels < ActiveRecord::Migration[4.2]

  def change
    create_table :invoice_configs do |t|
      t.integer :sequence_number, null: false, default: 1
      t.integer :due_days, null: false, default: 30
      t.belongs_to :group, index: true, null: false
      t.integer :contact_id, index: true
      t.integer :page_size, default: 15
      t.text :address
      t.text :payment_information
    end

    create_table :invoices do |t|
      t.string :title, null: false

      t.string :sequence_number, null: false, index: :unique
      t.string :state, null: false, default: :draft
      t.string :esr_number, null: false, index: :unique

      t.text :description

      t.string :recipient_email
      t.text :recipient_address

      t.date :sent_at
      t.date :due_at

      t.belongs_to :group, index: true, null: false
      t.belongs_to :recipient, index: true, null: false

      t.decimal :total, precision: 12, scale: 2

      t.timestamps null: false
    end

    create_table :invoice_items do |t|
      t.belongs_to :invoice, index: true, null: false

      t.string :name, null: false
      t.text :description

      t.decimal :vat_rate, precision: 5, scale: 2
      t.decimal :unit_cost, precision: 12, scale: 2, null: false
      t.integer :count, default: 1, null: false
    end

    create_table :payments do |t|
      t.belongs_to :invoice, index: true, null: false
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.date :received_at, null: :false
    end

    create_table :payment_reminders do |t|
      t.belongs_to :invoice, index: true, null: false
      t.text :message
      t.date :due_at, null: false
      t.timestamps null: false
    end

    reversible do |dir|
      dir.up do
        conn = ActiveRecord::Base.connection
        ids = select_values("SELECT id FROM #{conn.quote_table_name('groups')} WHERE id = layer_group_id")
        values = ids.collect { |id| "(#{id})" }.join(', ')
        execute("INSERT INTO invoice_configs (group_id) VALUES #{values}") if ids.present?
      end
    end
  end

end
