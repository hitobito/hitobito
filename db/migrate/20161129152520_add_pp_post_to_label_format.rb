class AddPpPostToLabelFormat < ActiveRecord::Migration
  def change
    add_column :label_formats, :pp_post, :string, default: nil
  end
end
