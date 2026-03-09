class TranslateInvoiceRuns < ActiveRecord::Migration[8.0]
  def up
    unless ActiveRecord::Base.connection.table_exists?('invoice_run_translations')
      say_with_time('creating translation table for invoice runs') do
        InvoiceRun.create_translation_table!(
          {
            title: :string,
          },
          { migrate_data: true, remove_source_columns: true }
        )
      end
    end
  end

  def down
    say_with_time('dropping translation table for invoice runs') do
      add_column :invoice_runs, :title, :string, null: true
      InvoiceRun.find_each { |run| run.update_column(:title, run.name) }
      change_column_null :invoice_runs, :title, false

      InvoiceRun.drop_translation_table!
    end
  end
end
