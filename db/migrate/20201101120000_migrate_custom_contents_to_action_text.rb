# frozen_string_literal: true

class MigrateCustomContentsToActionText < ActiveRecord::Migration[6.0]

  include ActionView::Helpers::TextHelper

  def change
    rename_column :custom_content_translations, :body, :body_old
    CustomContent::Translation.find_each do |cct|
      cct.update_attribute(:body, simple_format(cct.body_old))
    end
    remove_column :custom_content_translations, :body_old
  end

end
