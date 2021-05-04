# frozen_string_literal: true

#  Copyright (c) 2020, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Export::Pdf::Messages::Letter
  class Section
    include ActionView::Helpers::SanitizeHelper

    attr_reader :pdf, :message

    delegate :bounds, :table, :cursor, :font_size, :text_box,
             :fill_and_stroke_rectangle, :fill_color, :image, :group, to: :pdf

    delegate :recipients, :content, to: :message


    def initialize(pdf, letter, options = {})
      @pdf = pdf
      @letter = letter

      @debug = options[:debug]
      @stamped = options[:stamped]
      @cursors = {}
    end

    private

    def with_settings(opts = {})
      before = opts.map { |key, _value| [key, pdf.send(key)] }
      opts.each { |key, value| pdf.send(:"#{key}=", value) }
      yield
      before.each { |key, value| pdf.send(:"#{key}=", value) }
    end

    def text(*args)
      options = args.extract_options!
      pdf.text args.join(' '), options
    end

    def bounding_box(top_left, attrs = {})
      pdf.bounding_box(top_left, attrs) do
        yield
        pdf.transparent(0.5) { pdf.stroke_bounds } if @debug
      end
    end

    def stamped(key, &block)
      return block.call unless @stamped
      puts "stamping"

      if stamp_missing?(key)
        pdf.create_stamp(key) { block.call }
        @cursors[key] = cursor
      end
      pdf.stamp key

      if cursor != @cursors[key]
        pdf.move_cursor_to @cursors[key]
      end
    end

    def stamp_missing?(key)
      !@cursors.key?(key)
    end
  end
end
