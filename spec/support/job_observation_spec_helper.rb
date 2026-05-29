#  Copyright (c) 2012-2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module JobObservationSpecHelper
  def read_data_from_generated_file(observable_job)
    data = observable_job.generated_file.download
    if observable_job.filetype.to_sym == :csv && data.present?
      data = data.force_encoding(Settings.csv.encoding)
    end
    data
  end
end
