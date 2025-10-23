#  Copyright (c) 2012-2025, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
class RemoveNullConstraintsFromCustomContentTranslations < ActiveRecord::Migration[7.1]
  def change
    change_column_null :custom_content_translations, :label, true
  end
end
