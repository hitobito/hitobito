class RemoveNullConstraintsFromCustomContentTranslations < ActiveRecord::Migration[7.1]
  def change
    change_column_null :custom_content_translations, :label, true
  end
end
