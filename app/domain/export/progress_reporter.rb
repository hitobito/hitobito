# frozen_string_literal: true

#  Copyright (c) 2021, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export
  class ProgressReporter
    attr_reader :file

    def initialize(file, total)
      @file = file.parent.join(file.basename(".*").to_s << ".progress")
      @total = total
    end

    def report(position)
      value = percentage(position)
      if steps.first <= value
        steps.delete_if { |step| step <= value }
        update_file(value)
      end
    end

    private

    def update_file(value)
      FileUtils.mkdir_p(@file.dirname) unless @file.dirname.exist?
      @file.write(value.to_i)
      FileUtils.rm_rf(@file) if steps.empty?
    end

    def steps
      @steps ||= (0..100).to_a
    end

    def percentage(position)
      ((position / @total.to_f) * 100).to_i
    end
  end
end
