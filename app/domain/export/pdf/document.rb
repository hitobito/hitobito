# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Export::Pdf::Document
  attr_accessor :pdf

  DEFAULT_FONT = "NotoSans"
  FALLBACK_FONT = DEFAULT_FONT

  def initialize(page_size: "A4", page_layout: :portrait, margin: 2.cm, **opts)
    @pdf = Prawn::Document.new(page_size:, page_layout:, margin:, fallback_fonts: [FALLBACK_FONT], **opts)
    set_font
  end

  private

  def set_font
    replace_included_fonts_with_ttf_variants

    # font family to use as fallback font
    @pdf.font_families.update(DEFAULT_FONT => {
      normal: font_path("NotoSans-Regular.ttf"),
      bold: font_path("NotoSans-Bold.ttf"),
      italic: font_path("NotoSans-Italic.ttf"),
      bold_italic: font_path("NotoSans-BoldItalic.ttf")
    })

    @pdf.font DEFAULT_FONT
    @pdf.font_size Settings.pdf.font_size
  end

  private

  def font_path(name)
    Rails.root.join("app", "javascript", "fonts", name)
  end

  # Fallback fonts are not used when rendering with included default fonts.
  # When trying to render a text with characters outside of the Windows-1252 character set,
  # Prawn will raise an error.
  # Replacing included default fonts with roughly equivalent ttf fonts fixes this issue.
  def replace_included_fonts_with_ttf_variants
    @pdf.font_families.clear

    # use LiberationSans instead of Helvetica
    @pdf.font_families.update("LiberationSans" => {
      normal: font_path("LiberationSans-Regular.ttf"),
      bold: font_path("LiberationSans-Bold.ttf"),
      italic: font_path("LiberationSans-Italic.ttf"),
      bold_italic: font_path("LiberationSans-BoldItalic.ttf")
    })

    # use LiberationMono instead of Courier
    @pdf.font_families.update("LiberationMono" => {
      normal: font_path("LiberationMono-Regular.ttf"),
      bold: font_path("LiberationMono-Bold.ttf"),
      italic: font_path("LiberationMono-Italic.ttf"),
      bold_italic: font_path("LiberationMono-BoldItalic.ttf")
    })

    # use CommonSerif instead of Times-Roman
    @pdf.font_families.update("CommonSerif" => {
      normal: font_path("CommonSerif-Regular.ttf"),
      bold: font_path("CommonSerif-Bold.ttf"),
      italic: font_path("CommonSerif-Italic.ttf"),
      bold_italic: font_path("CommonSerif-BoldItalic.ttf")
    })

    # alias the default font so not to break existing code
    @pdf.font_families.update("Helvetica" => @pdf.font_families["LiberationSans"])
  end
end
