# frozen_string_literal: true

#  Copyright (c) 2021, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Pdf
  class Section

    attr_reader :pdf, :model

    delegate :bounds, :text, :cursor, :font_size, :text_box,
             :fill_and_stroke_rectangle, :fill_color,
             :image, :group, :move_cursor_to, :float,
             :stroke_bounds, :stamp, :create_stamp,
             :bounds, :table, :cursor, :font_size, :text_box,
             :fill_and_stroke_rectangle, :fill_color, :image,
             to: :pdf


    def initialize(pdf, model, options)
      @pdf = pdf
      @model = model
      @options = options

      @debug = options[:debug]
      @stamped = options[:stamped]
      @cursors = {}
    end

    private

    def bounding_box(top_left, attrs = {})
      pdf.bounding_box(top_left, attrs) do
        yield
        pdf.transparent(0.5) { stroke_bounds } if @debug
      end
    end

    def stamped(key, &block)
      return block.call unless @stamped

      if stamp_missing?(key)
        create_stamp(key) { block.call }
        @cursors[key] = cursor
      end
      stamp key

      if cursor != @cursors[key]
        move_cursor_to @cursors[key]
      end
    end

    def stamp_missing?(key)
      !@cursors.key?(key)
    end
  end
end
