#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# We want to be able to create temporary active storage blobs for longer background data calculations
# over multiple jobs.
class AddTemporaryToActiveStorageBlobs < ActiveRecord::Migration[8.0]
  def change
    add_column :active_storage_blobs, :temporary, :boolean, default: false
  end
end
