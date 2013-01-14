class AddJsDescriptionToEventKinds < ActiveRecord::Migration
  def change
    add_column :event_kinds, :j_s_description, :string
  end
end
