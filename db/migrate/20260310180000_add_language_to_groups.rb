# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddLanguageToGroups < ActiveRecord::Migration[8.0]
  def up
    if column_exists? :groups, :language
      available = Settings.application.languages.keys + Settings.application.additional_languages.keys
      Group.where.not(language: available).or(Group.where(language: nil)).update_all(language: default_language)
      change_column :groups, :language, :string, default: default_language, null: false
    else
      add_column :groups, :language, :string, default: default_language, null: false
    end
    Group.reset_column_information
  end

  def down
    # This is not exactly the right thing to do in the SBV, DSJ and SAC case, but
    # it's better than raising ActiveRecord::IrreversibleMigration which would
    # prevent some of our migration specs from running.
    remove_column :groups, :language
    Group.reset_column_information
  end

  private

  def default_language
    Settings.application.languages.keys.first
  end
end
