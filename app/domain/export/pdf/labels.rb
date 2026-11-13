#  Copyright (c) 2012-2026, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Pdf
  class Labels
    MIN_FONT_SIZE = 5

    attr_reader :format, :category_key

    def initialize(format, category_key: nil)
      @format = format
      @category_key = category_key
    end

    def generate(contactables, household = false)
      pdf = Export::Pdf::Document.new(page_size: format.page_size, page_layout: format.page_layout,
        margin: 0.cm).pdf
      pdf.font_size = format.font_size
      if household
        generate_with_households(contactables, pdf)
      else
        generate_without_households(contactables, pdf)
      end
      pdf.render
    end

    private

    def generate_with_households(contactables, pdf)
      households = Export::Tabular::People::Households.new(contactables, retain_order: true)
      households.list.each_with_index do |household, i|
        name = to_name(household)
        address = household_address(household, name)
        print_address_in_bounding_box(pdf, address, position(pdf, i))
      end
    end

    def generate_without_households(contactables, pdf)
      contactables.each_with_index do |contactable, i|
        name = to_name(contactable)
        address = address(contactable, name)
        print_address_in_bounding_box(pdf, address, position(pdf, i))
      end
    end

    def to_name(contactable)
      Export::Tabular::People::HouseholdRow.new(contactable).name
    end

    def print_address_in_bounding_box(pdf, address, pos) # rubocop:todo Metrics/AbcSize
      pdf.bounding_box(pos,
        width: format.width.mm - min_border,
        height: format.height.mm - min_border) do
        left = format.padding_left.mm
        top = format.height.mm - format.padding_top.mm - min_border
        # pdf.stroke_bounds
        print_address_with_pp_post(pdf, address, left, top)
      end
    end

    # print without line wrap
    def print_address(pdf, address, pos)
      left = pos.first + format.padding_left.mm
      top = pos.last - format.padding_top.mm
      print_address_with_pp_post(pdf, address, left, top)
    end

    def print_address_with_pp_post(pdf, address, left, top)
      if format.pp_post?
        print_pp_post(pdf, [left, top])
        top -= 7.mm
      end
      size = fitting_font_size(pdf, address.lines.size, top - pdf.bounds.bottom)
      truncator = Export::Pdf::LineTruncator.new(pdf, pdf.bounds.right - left, size:)
      pdf.text_box(truncator.truncate(address), at: [left, top], size:)
    end

    def fitting_font_size(pdf, line_count, height)
      format.font_size.step(MIN_FONT_SIZE, -0.5).find do |size|
        line_count * pdf.font.height_at(size) <= height
      end || MIN_FONT_SIZE
    end

    def household_address(contactable, name)
      Person::Address.new(contactable.first, category_key:).for_pdf_label(name)
    end

    def address(contactable, name)
      Person::Address.new(contactable, category_key:).for_pdf_label(name, format.nickname?)
    end

    def position(pdf, i) # rubocop:todo Metrics/AbcSize
      page_index = i % (format.count_horizontal * format.count_vertical)
      if page_index == 0 && i > 0
        pdf.start_new_page
      end

      x = page_index % format.count_horizontal
      y = page_index / format.count_horizontal

      [x * format.width.mm, pdf.margin_box.height - (y * format.height.mm)]
    end

    def print_pp_post(pdf, at)
      pdf.text_box("<u><font size='12'><b>P.P.</b></font> " \
                   "<font size='8'>#{format.pp_post}  Post CH AG</font></u>",
        inline_format: true,
        at: at)
    end

    def min_border
      Settings.pdf.labels.min_border.to_i.mm
    end
  end
end
