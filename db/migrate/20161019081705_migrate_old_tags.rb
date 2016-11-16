class MigrateOldTags < ActiveRecord::Migration
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
