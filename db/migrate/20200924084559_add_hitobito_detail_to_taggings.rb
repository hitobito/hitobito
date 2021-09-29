# frozen_string_literal: true

class AddHitobitoDetailToTaggings < ActiveRecord::Migration[6.0]
  def change
    add_column :taggings, :hitobito_tooltip, :string
  end
end
