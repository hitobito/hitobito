# frozen_string_literal: true

#  Copyright (c) 2012-2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddMutationIdToVersions < ActiveRecord::Migration[7.1]
  def change
    change_table(:versions) do |t|
      t.column :mutation_id, :string, index: true
    end
  end
end
