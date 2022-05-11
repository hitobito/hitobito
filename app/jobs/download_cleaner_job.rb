# frozen_string_literal: true

#  Copyright (c) 2012-2022, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class DownloadCleanerJob < RecurringJob

  run_every 1.day

  def perform_internal
    remove_old_downloads
  end

  private

  def remove_old_downloads
    AsyncDownloadFile.where(older_than_a_day).find_each do |file|
      next unless file.generated_file.attached?

      file.destroy
    end
  end

  def older_than_a_day
    AsyncDownloadFile.arel_table[:timestamp].lt(1.day.ago.to_i)
  end

end
