class RenameItemIdToTemplateItemIdOnInvoiceRunProcessedSubjects < ActiveRecord::Migration[8.0]
  def change
    InvoiceRun::ProcessedSubject.delete_all

    change_table :invoice_run_processed_subjects do |t|
      t.remove_index [:subject_id, :subject_type, :item_id, :invoice_id], name: "index_processed_subjects", unique: true
      t.remove_index [:subject_type, :subject_id], name: "index_invoice_run_processed_subjects_on_subject"

      t.rename :item_id, :template_item_id
      t.remove :invoice_id, type: :bigint, null: false
      t.belongs_to :item, null: false

      t.index [:subject_type, :subject_id, :template_item_id], name: "index_unique_processed_subjects", unique: true
      t.index [:subject_type, :subject_id, :template_item_id, :item_id], name: "index_processed_subjects"
    end
  end
end
