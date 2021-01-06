# frozen_string_literal: true

#  Copyright (c) 2020, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

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
