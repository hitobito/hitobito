#  Copyright (c) 2026 Schweizer Alpenclub SAC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class CopyCustomContentPlaceholders < ActiveRecord::Migration[8.0]
  def up
    contents_with_context = CustomContent.unscoped.where.not(context: nil)
    keys = contents_with_context.distinct.pluck(:key)
    keys.each do |key|
      main = CustomContent.where(context: nil).find_by(key: key)
      next unless main

      contents_with_context.where(key: key).update_all(
        placeholders_optional: main.placeholders_optional,
        placeholders_required: main.placeholders_required
      )
    end
  end

  def down
  end
end
