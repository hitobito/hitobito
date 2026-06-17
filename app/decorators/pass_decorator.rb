#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class PassDecorator < ApplicationDecorator
  delegate :member_number, :member_name, to: :wallet_data_provider
  delegate :name, :description, :background_color, :logo_icon, :logo_banner, to: :definition
  decorates :pass

  def definition = pass_definition

  def active?
    eligible? &&
      valid_from <= Date.current &&
      (valid_until.nil? || valid_until >= Date.current)
  end

  def qrcode_value
    Passes::VerificationQrCode.new(self).verify_url
  end

  def logo_path
    attachment = definition.logo_banner(person.language)
    return nil unless attachment&.attached?
    helpers.url_for(attachment)
  end

  def to_s = pass_definition.name

  def to_h
    {
      definition_id: definition.id,
      definition_name: definition.name,
      person_id: person.id,
      member_number: member_number,
      member_name: member_name,
      valid_from: valid_from,
      valid_until: valid_until,
      qrcode_value: qrcode_value
    }
  end

  # Returns the normalized background color (without # prefix, defaults to white)
  def pdf_background_color
    color = background_color.to_s
    color.delete_prefix("#").presence || "FFFFFF"
  end

  # Returns color scheme for text based on background color luminance
  def text_colors
    light = light_background?
    {
      text: light ? "333333" : "FFFFFF",
      muted: light ? "666666" : "CCCCCC",
      label: light ? "888888" : "AAAAAA"
    }
  end

  def wallet_data_provider
    @wallet_data_provider ||= definition.template.wallet_data_provider.new(self)
  end

  private

  # Determines if the background color is light or dark based on luminance
  def light_background?
    ColorLuminance.light?(pdf_background_color)
  end
end
