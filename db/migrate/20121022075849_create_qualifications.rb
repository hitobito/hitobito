# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class CreateQualifications < ActiveRecord::Migration[4.2]
  def change
    create_table :qualification_kinds do |t|
      t.string :label, null: false
      t.integer :validity
      t.string :description, limit: 1023

      t.timestamps
      t.datetime :deleted_at
    end

    create_table :qualifications do |t|
      t.belongs_to :person, null: false
      t.belongs_to :qualification_kind, null: false

      t.date :start_at, null: false
      t.date :finish_at
    end

    create_table :event_kinds_preconditions do |t|
      t.belongs_to :event_kind, null: false
      t.belongs_to :qualification_kind, null: false
    end

    create_table :event_kinds_qualification_kinds do |t|
      t.belongs_to :event_kind, null: false
      t.belongs_to :qualification_kind, null: false
    end

    create_table :event_kinds_prolongations do |t|
      t.belongs_to :event_kind, null: false
      t.belongs_to :qualification_kind, null: false
    end

    add_column :event_kinds, :minimum_age, :integer
  end
end
