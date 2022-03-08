# frozen_string_literal: true

#  Copyright (c) 2012-2022, Schweizer Wanderwege. This file is part of
#  hitobito_sww and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddLanguageToPeople < ActiveRecord::Migration[6.1]
  def change
    add_column :people, :language, :string, default: default_language, null: false
  end

  private

  def default_language
    Settings.application.languages.keys.first
  end
end
