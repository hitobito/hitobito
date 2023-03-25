class AddSalutationTitleToPerson < ActiveRecord::Migration[6.0]
  def change
    add_column(:people, :title, :string, null: true) unless column_exists?(:people, :title)
    add_column(:people, :salutation, :string, null: true) unless column_exists?(:people, :salutation)
    Person.reset_column_information
  end
end
