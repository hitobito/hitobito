# frozen_string_literal: true

#  Copyright (c) 2020-2026, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Pdf::ShippingInfoRenderers
  SHIPPING_INFO_FONT = "NotoSans"
  SHIPPING_METHODS = {
    own: ["", 8.pt],
    normal: ["<b><font size='12'>P.P.</font></b> ", 12.pt],
    priority: ["<b><font size='12'>P.P.</font> <font size='24pt'>A</font></b> ", 24.pt]
  }.freeze

  def render_shipping_info(shippable, width:)
    pdf.font(SHIPPING_INFO_FONT) do
      render_shipping_info_post_logo(width) unless shippable.effective_shipping_method == "own"
      render_shipping_info_text(shippable, width)
      render_shipping_info_line(width) if shippable.shipping_info?
    end
  end

  private

  def render_shipping_info_post_logo(width)
    text_box("Post CH AG", align: :center, size: 7.pt, width: width, at: [0, cursor + 18.pt])
  end

  def render_shipping_info_text(shippable, width)
    shipping_method_text, text_height = SHIPPING_METHODS[shippable.effective_shipping_method.to_sym]
    text_box("#{shipping_method_text}<font size='8'>#{shippable.effective_pp_post}</font>",
      inline_format: true, overflow: :truncate, single_line: true,
      width: width, at: [0, cursor + text_height])
  end

  def render_shipping_info_line(width)
    pdf.stroke do
      pdf.move_down 2.mm
      pdf.horizontal_line 0, width
      pdf.move_up 2.mm
    end
  end
end
