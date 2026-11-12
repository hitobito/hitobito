# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Pdf
  class LineTruncator
    def initialize(pdf, width, **font_options)
      @pdf = pdf
      @width = width
      @font_options = font_options
    end

    def truncate(text)
      text.to_s.split("\n", -1).map { |line| truncate_line(line) }.join("\n")
    end

    private

    def truncate_line(line)
      line = line.chop while @pdf.width_of(line, @font_options) > @width
      line
    end
  end
end
