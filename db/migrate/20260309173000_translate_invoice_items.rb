class TranslateInvoiceItems < ActiveRecord::Migration[8.0]
  # Class stubs used because these classes have been removed from the codebase in the meantime,
  # but in this migration some invoice items of that type may still be loaded before wagon migrations
  # get to clean them up.
  class InvoiceItem::FixedFee < InvoiceItem
  end
  class InvoiceItem::Roles < InvoiceItem::FixedFee
  end

  def up
    remove_column :invoice_items, :search_column, if_exists: true
    say_with_time('creating translation table for period invoice template items') do
      PeriodInvoiceTemplate::Item.create_translation_table!(
        {
          name: :string,
        },
        { migrate_data: true, remove_source_columns: true }
      )
    end
    say_with_time('creating translation table for invoice items') do
      InvoiceItem.create_translation_table!(
        {
          name: :string,
        },
        { migrate_data: true, remove_source_columns: true }
      )
    end
  end

  def down
    say_with_time('dropping translation table for invoice items') do
      add_column :invoice_items, :name, :string, null: true
      InvoiceItem.find_each { |item| item.update_column(:name, item.name) }
      change_column_null :invoice_items, :name, false

      InvoiceItem.drop_translation_table!
    end

    say_with_time('dropping translation table for period invoice template items') do
      add_column :period_invoice_template_items, :name, :string, null: true
      PeriodInvoiceTemplate::Item.find_each { |item| item.update_column(:name, item.name) }
      change_column_null :period_invoice_template_items, :name, false

      PeriodInvoiceTemplate::Item.drop_translation_table!
    end

  end
end
