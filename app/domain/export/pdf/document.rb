# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Export::Pdf::Document
  attr_accessor :pdf

  def initialize(page_size: "A4", page_layout: :portrait, margin: 2.cm, **opts)
    @pdf = Prawn::Document.new(page_size:, page_layout:, margin:, fallback_fonts: ["NotoSans"], **opts)
    set_font
  end

  private

  def set_font
    @pdf.font_families.update("NotoSans" => {
      normal: font_path("NotoSans-Regular.ttf"),
      bold: font_path("NotoSans-Bold.ttf"),
      italic: font_path("NotoSans-Italic.ttf"),
      bold_italic: font_path("NotoSans-BoldItalic.ttf")
    })
    @pdf.font_families.update("LiberationSans" => {
      normal: font_path("LiberationSans/LiberationSans-Regular.ttf"),
      bold: font_path("LiberationSans/LiberationSans-Bold.ttf"),
      italic: font_path("LiberationSans/LiberationSans-Italic.ttf"),
      bold_italic: font_path("LiberationSans/LiberationSans-BoldItalic.ttf")
    })
    @pdf.font "NotoSans"
    @pdf.font_size Settings.pdf.font_size
  end

  private

  def font_path(name)
    Rails.root.join("app", "javascript", "fonts", name)
  end
end
