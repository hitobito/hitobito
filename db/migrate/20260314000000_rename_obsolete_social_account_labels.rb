#  Copyright (c) 2026, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class RenameObsoleteSocialAccountLabels < ActiveRecord::Migration[8.0]
  RENAMED = {
    "Twitter" => "X (Twitter)"
  }.freeze

  REMOVED = ["MSN", "Skype"].freeze

  def up
    RENAMED.each do |old_label, new_label|
      execute "UPDATE social_accounts SET label = #{quote(new_label)} WHERE label = #{quote(old_label)}"
    end
    REMOVED.each do |old_label|
      execute "UPDATE social_accounts SET label = 'Andere', name = #{quote(old_label)} || ':' || name WHERE label = #{quote(old_label)}"
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
