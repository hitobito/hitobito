#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module People::PassesHelper
  def google_wallet_configured?
    Wallets::GoogleWallet::Config.exist?
  end

  def apple_wallet_configured?
    defined?(Wallets::AppleWallet::Config) && Wallets::AppleWallet::Config.exist?
  end

  # Returns 'pass-card--dark-bg' if the background color is dark, nil otherwise.
  # Uses the same W3C luminance formula as Export::Pdf::Passes::Default.
  def pass_card_bg_class(hex_color)
    return nil if hex_color.blank?

    hex = hex_color.delete_prefix("#")
    return nil if hex.length != 6

    r = hex[0..1].to_i(16)
    g = hex[2..3].to_i(16)
    b = hex[4..5].to_i(16)
    luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0
    luminance <= 0.5 ? "pass-card--dark-bg" : nil
  end
end
