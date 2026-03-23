# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

module People::PassesHelper
  # Resolves a pass template partial with fallback to the "default" template.
  # If the template provides e.g. only _card_front, the missing _card_back and
  # _verify partials are loaded from passes/templates/default/ instead.
  def pass_template_partial(template_name, partial_name)
    path = "passes/templates/#{template_name}/_#{partial_name}"
    if template_name != "default" && lookup_context.find_all(path).empty?
      "passes/templates/default/#{partial_name}"
    else
      "passes/templates/#{template_name}/#{partial_name}"
    end
  end

  def google_wallet_configured?
    Wallets::GoogleWallet::Config.exist?
  end

  def apple_wallet_configured?
    Wallets::AppleWallet::Config.exist?
  end

  # Renders an inline SVG QR code for the pass verification URL.
  def pass_qr_code_svg(pass, size: 120)
    RQRCode::QRCode.new(pass.qrcode_value).as_svg(
      module_size: 3, standalone: true, use_path: true, viewbox: true,
      svg_attributes: {width: size, height: size, class: "pass-card-qr-svg"}
    ).html_safe
  end

  # Returns inline style for pass card with background color and adaptive text color CSS variables.
  def pass_card_style(pass)
    color = pass.definition.background_color
    is_light = ColorLuminance.light?(color)

    text_vars = if is_light
      # Dark text on light background
      "--pass-text: #333; --pass-text-muted: #666; --pass-text-label: #888;"
    else
      # Light text on dark background
      "--pass-text: #fff; --pass-text-muted: #ccc; --pass-text-label: #aaa;"
    end

    "background-color: #{color}; #{text_vars}"
  end
end
