# encoding: utf-8

#  Copyright (c) 2017, Dachverband Schweizer Jugendparlamente. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class CreateNotes < ActiveRecord::Migration[4.2]
  def change
    rename_table :person_notes, :notes
    add_column :notes, :subject_type, :string
    rename_column :notes, :person_id, :subject_id

    Note.update_all(subject_type: Person.name)
  end
end
