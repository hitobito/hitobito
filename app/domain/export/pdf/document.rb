# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Export::Pdf::Document
  attr_accessor :pdf

  def initialize(page_size: "A4", page_layout: :portrait, margin: 2.cm)
    @pdf = Prawn::Document.new(page_size: page_size, page_layout: page_layout, margin: margin)
    set_font
  end

  private

  def set_font
    @pdf.font_families.update("Roboto" => {
      normal: font_path("roboto-regular.ttf"),
      bold: font_path("roboto-bold.ttf"),
      italic: font_path("roboto-italic.ttf"),
      bold_italic: font_path("roboto-bold-italic.ttf")
    })
    @pdf.font "Roboto"
    @pdf.font_size Settings.pdf.font_size
  end

  private

  def font_path(name)
    Rails.root.join("app", "javascript", "fonts", name)
  end
end
