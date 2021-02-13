# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Pdf
  class Labels

    attr_reader :format

    def initialize(format)
      @format = format
    end

    def generate(contactables, household = false)
      pdf = Prawn::Document.new(page_size: format.page_size,
                                page_layout: format.page_layout,
                                margin: 0.mm)
      pdf.font Settings.pdf.labels.font_name, size: format.font_size

      rows = household ? to_households(contactables) : contactables

      rows.each_with_index do |contactable, i|
        name = to_name(contactable)

        print_address_in_bounding_box(pdf,
                                      address(contactable, name),
                                      position(pdf, i))
      end

      pdf.render
    end

    private

    def to_households(contactables)
      Export::Tabular::People::Households.new(contactables).list
    end

    def to_name(contactable)
      Export::Tabular::People::HouseholdRow.new(contactable).name
    end

    # print with automatic line wrap
    def print_address_in_bounding_box(pdf, address, pos)
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
      pdf.text_box(address, at: [left, top], overflow: :shrink_to_fit)
    end

    def address(contactable, name)
      address = ""
      address << contactable.company_name << "\n" if print_company?(contactable)
      address << contactable.nickname << "\n" if print_nickname?(contactable)
      address << name << "\n" if name.present?
      address << contactable.address.to_s
      address << "\n" unless contactable.address =~ /\n\s*$/
      address << contactable.zip_code.to_s << " " << contactable.town.to_s << "\n"
      address << contactable.country_label unless contactable.ignored_country?
      address
    end

    def position(pdf, i)
      page_index = i % (format.count_horizontal * format.count_vertical)
      if page_index == 0 && i > 0
        pdf.start_new_page
      end

      x = page_index % format.count_horizontal
      y = page_index / format.count_horizontal

      [x * format.width.mm, pdf.margin_box.height - (y * format.height.mm)]
    end

    def print_company?(contactable)
      contactable.try(:company) && contactable.company_name?
    end

    def print_nickname?(contactable)
      format.nickname? && contactable.respond_to?(:nickname) && contactable.nickname.present?
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
