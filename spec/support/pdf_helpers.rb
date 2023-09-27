# frozen_string_literal: true

#  Copyright (c) 2023, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module PdfHelpers
  extend ActiveSupport::Concern

  def text_with_position(inspector = PDF::Inspector::Text.analyze(pdf.try(:render) || pdf))
    inspector.positions.each_with_index.collect do |p, i|
      p.collect(&:round) + [inspector.show_text[i]]
    end
  end

  def image_positions(page_no = 1)
    rendered_pdf = pdf.try(:render) || pdf
    io = StringIO.new(rendered_pdf)

    PDF::Reader.open(io) do |reader|
      page = reader.page(page_no)

      # Extract all XObjects of type :Image from the page
      images = page.xobjects.select { |_, obj| obj.hash[:Subtype] == :Image }

      images.map do |label, obj|
        width = obj.hash[:Width]
        height = obj.hash[:Height]

        # Pattern to match the transformation matrix followed by the image drawing
        pattern = /([-+]?[0-9]*\.?[0-9]+)\s+([-+]?[0-9]*\.?[0-9]+)\s+([-+]?[0-9]*\.?[0-9]+)\s+([-+]?[0-9]*\.?[0-9]+)\s+([-+]?[0-9]*\.?[0-9]+)\s+([-+]?[0-9]*\.?[0-9]+)\s+cm\s+\/#{label}\s+Do/

        if match = page.raw_content.match(pattern)
          # The transformation matrix components
          a = match[1].to_f
          b = match[2].to_f
          c = match[3].to_f
          d = match[4].to_f
          e = match[5].to_f
          f = match[6].to_f

          # Position in PDF units (this is the bottom-left corner of the image)
          x_position = e
          y_position = f

          # Dimensions in PDF units (taking scale factors from the transformation matrix)
          displayed_width = a * width
          displayed_height = d * height

          {x: x_position, y: y_position, width: width, height: height, displayed_width: displayed_width, displayed_height: displayed_height}
        else
          raise "Could not determine the details of the image with label #{label}."
        end
      end
    end
  end
end
