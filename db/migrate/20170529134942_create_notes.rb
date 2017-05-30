class CreateNotes < ActiveRecord::Migration
  def change
    rename_table :person_notes, :notes
    add_column :notes, :subject_type, :string
    rename_column :notes, :person_id, :subject_id

    Note.update_all(subject_type: Person.name)
  end
end
