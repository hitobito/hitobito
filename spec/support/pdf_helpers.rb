# frozen_string_literal: true

#  Copyright (c) 2023, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module PdfHelpers
  extend ActiveSupport::Concern

  def text_with_position(inspector = PDF::Inspector::Text.analyze(pdf.render))
    inspector.positions.each_with_index.collect do |p, i|
      p.collect(&:round) + [inspector.show_text[i]]
    end
  end
end
