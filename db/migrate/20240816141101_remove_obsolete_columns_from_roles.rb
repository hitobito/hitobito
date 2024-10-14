# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class RemoveObsoleteColumnsFromRoles < ActiveRecord::Migration[6.1]
  def change
    change_table :roles, bulk: true do |t|
      t.remove :deleted_at, type: :datetime
      t.remove :delete_on, type: :date
      t.remove :convert_on, type: :date
      t.remove :convert_to, type: :string
    end
  end
end
