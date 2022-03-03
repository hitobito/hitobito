class AddLanguageToPeople < ActiveRecord::Migration[6.1]
  def change
    add_column :people, :language, :string, default: default_language, null: false
  end

  private

  def default_language
    Settings.application.languages.keys.first
  end
end
