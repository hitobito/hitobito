# frozen_string_literal: true

class MigrateHelpTextsToActionText < ActiveRecord::Migration[6.0]

  include ActionView::Helpers::TextHelper

  def change
    rename_column :help_text_translations, :body, :body_old
    HelpText::Translation.find_each do |htt|
      htt.update_attribute(:body, simple_format(htt.body_old))
    end
    remove_column :help_text_translations, :body_old
  end

end
