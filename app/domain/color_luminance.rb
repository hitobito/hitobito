# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

module ColorLuminance
  module_function

  # Calculates the relative luminance of a color using the WCAG 2.x formula.
  # See https://www.w3.org/TR/WCAG20/#relativeluminancedef
  def calculate(hex_color)
    return nil if hex_color.blank?

    hex = hex_color.delete_prefix("#")
    return nil if hex.length != 6

    r = linearize(hex[0..1].to_i(16))
    g = linearize(hex[2..3].to_i(16))
    b = linearize(hex[4..5].to_i(16))

    0.2126 * r + 0.7152 * g + 0.0722 * b
  end

  def light?(hex_color)
    luminance = calculate(hex_color)
    luminance ? luminance > 0.5 : false
  end

  def dark?(hex_color)
    luminance = calculate(hex_color)
    luminance ? luminance <= 0.5 : false
  end

  def linearize(channel)
    c = channel / 255.0
    (c <= 0.04045) ? c / 12.92 : ((c + 0.055) / 1.055)**2.4
  end
end
