#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Pdf::Passes::Sections
  # Renders crop marks around the pass cards and a fold line between them.
  # Crop marks help with precise cutting when printing, and the fold line
  # indicates where to fold the card to create a double-sided pass.
  class CropMarks
    def initialize(pdf, pass_decorator, card_layout)
      @pdf = pdf
      @pass_decorator = pass_decorator
      @card_layout = card_layout
    end

    def render
      @pdf.line_width = 0.25
      draw_outer_corner_marks
      draw_fold_line_marks
    end

    private

    def outer_corners
      front_x = @card_layout.front_x
      back_right_x = @card_layout.back_x + @card_layout.card_width
      top_y = @card_layout.card_y
      bottom_y = @card_layout.card_y - @card_layout.card_height

      [
        [front_x, top_y],
        [back_right_x, top_y],
        [front_x, bottom_y],
        [back_right_x, bottom_y]
      ]
    end

    def draw_outer_corner_marks
      outer_corners.each_with_index do |(cx, cy), i|
        draw_corner_mark(cx, cy, h_dir: (i % 2 == 0) ? -1 : 1, v_dir: (i < 2) ? 1 : -1)
      end
    end

    def draw_corner_mark(cx, cy, h_dir:, v_dir:)
      offset = @card_layout.crop_mark_offset
      length = @card_layout.crop_mark_length

      @pdf.stroke_line([cx + h_dir * offset, cy], [cx + h_dir * (offset + length), cy])
      @pdf.stroke_line([cx, cy + v_dir * offset], [cx, cy + v_dir * (offset + length)])
    end

    def draw_fold_line_marks
      fold_x = @card_layout.front_x + @card_layout.card_width
      top_start = @card_layout.card_y + @card_layout.crop_mark_offset
      bottom_start = @card_layout.card_y - @card_layout.card_height - @card_layout.crop_mark_offset

      @pdf.stroke_line([fold_x, top_start], [fold_x, top_start + @card_layout.crop_mark_length])
      @pdf.stroke_line([fold_x, bottom_start],
        [fold_x, bottom_start - @card_layout.crop_mark_length])
    end
  end
end
