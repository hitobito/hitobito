# frozen_string_literal: true

#  Copyright (c) 2021-2022, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export
  class ProgressReporter
    def initialize(file, total)
      @file = file
      @total = total

      @file.update(progress: 0)
    end

    def report(position)
      value = percentage(position)
      return if @file.progress >= value

      @file.update(progress: value)
    end

    private

    def percentage(position)
      ((position / @total.to_f) * 100).to_i
    end
  end
end
