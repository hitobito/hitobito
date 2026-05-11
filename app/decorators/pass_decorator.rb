#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class PassDecorator < SimpleDelegator
  delegate :member_number, :member_name, to: :wallet_data_provider
  delegate :name, :description, :background_color, to: :pass_definition

  def decorate = self

  def definition = pass_definition

  def active?
    eligible? &&
      valid_from <= Date.current &&
      (valid_until.nil? || valid_until >= Date.current)
  end

  def qrcode_value
    Passes::VerificationQrCode.new(self).verify_url
  end

  def logo_icon
    definition.logo_icon
  end

  def logo_icon_url
    attachment = definition.logo_icon
    return nil unless attachment&.attached?

    Rails.application.routes.url_helpers.rails_blob_url(attachment, host: Settings.oidc.issuer)
  end

  def logo_banner
    definition.logo_banner
  end

  def logo_banner_url
    attachment = definition.logo_banner
    return nil unless attachment&.attached?

    Rails.application.routes.url_helpers.rails_blob_url(attachment, host: Settings.oidc.issuer)
  end

  # Returns binary logo data for the current locale.
  # Uses the locale-aware logo_icon method from PassDefinition.
  def logo_blob
    attachment = definition.logo_icon
    return nil unless attachment&.attached?

    attachment.blob.download
  end

  # Returns an absolute URL for the logo (for use in wallet providers and PDF).
  # Uses the locale-aware logo_icon method from PassDefinition.
  def logo_url
    attachment = definition.logo_icon
    return nil unless attachment&.attached?

    Rails.application.routes.url_helpers.rails_blob_url(attachment, only_path: false)
  end

  # Returns a root-relative path suitable for use in HTML (image_tag).
  # Uses the locale-aware logo_icon method from PassDefinition.
  def logo_path
    attachment = definition.logo_icon
    return nil unless attachment&.attached?

    Rails.application.routes.url_helpers.rails_blob_path(attachment, only_path: true)
  end

  def to_s
    definition.name
  end

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
  # @return [Hash] Hash with :text, :muted, and :label color values
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
  # @return [Boolean] true if background is light, false if dark
  def light_background?
    ColorLuminance.light?(pdf_background_color)
  end
end
