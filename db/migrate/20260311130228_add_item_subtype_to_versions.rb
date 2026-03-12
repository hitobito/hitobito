#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# https://github.com/paper-trail-gem/paper_trail?tab=readme-ov-file#4b1-the-optional-item_subtype-column
# This stores STI models actual class, we use it for translations
class AddItemSubtypeToVersions < ActiveRecord::Migration[7.0]
  def change
    add_column :versions, :item_subtype, :string
  end
end