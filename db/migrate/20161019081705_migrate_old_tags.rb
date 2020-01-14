# encoding: utf-8

#  Copyright (c) 2016, hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class MigrateOldTags < ActiveRecord::Migration[4.2]
  def change
    migrate_tags
    drop_table :old_tags
  end

  private

  def migrate_tags
    query = Arel::Table.new(:old_tags)
      .project(Arel.sql('*'))
    select_all(query.to_sql).each { |row| migrate_row(row) }
  end

  def migrate_row(row)
    model_class = row['taggable_type'].constantize
    object = model_class.find(row['taggable_id'])
    object.tag_list.add(row['name'])
    object.save!
  end
end
