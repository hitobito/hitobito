#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class CleanupTemporaryBlobsJob < RecurringJob
  run_every 1.day

  def perform_internal
    ActiveStorage::Blob.temporary.where(created_at: ...24.hours.ago).find_each do |blob|
      blob.purge
    end
  end
end
