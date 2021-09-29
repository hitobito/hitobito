# frozen_string_literal: true

#  Copyright (c) 2021, CEVI Regionalverband ZH-SH-GL. This file is part of
#  hitobito_cevi and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cevi.

class AddArchivedAtToGroups < ActiveRecord::Migration[6.0]
  def change
    add_column :groups, :archived_at, :datetime
  end
end
