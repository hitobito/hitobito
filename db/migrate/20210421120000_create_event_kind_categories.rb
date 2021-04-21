#  frozen_string_literal: true

#  Copyright (c) 2012-2021, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class CreateEventKindCategories < ActiveRecord::Migration[6.0]
  def up
    create_table :event_kind_categories do |t|
      t.timestamps
      t.datetime "deleted_at"
    end
    Event::KindCategory.create_translation_table!(
        { label: :string, },
        { migrate_data: false, remove_source_columns: true }
    )
    add_column :event_kinds, :kind_category_id, :integer
  end

  def down
    remove_column :event_kinds, :kind_category_id
    Event::KindCategory.drop_translation_table! migrate_data: false
    drop_table :event_kind_categories
  end
end
