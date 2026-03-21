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
    # Passes::VerificationQrCode.new(person, definition).verify_url

    # Placeholder value for QR code, since Passes::VerificationQrCode is not implemented yet.
    "https://example.com/passes/#{definition.id}/verify/token"
  end

  # Resolve the closest group in the owner's ancestor chain that has a logo attached.
  # Walks from root to self, returns the first group with a logo.
  # Returns nil if no group has a logo.
  def logo_group
    return @logo_group if defined?(@logo_group)

    @logo_group = definition.owner.self_and_ancestors
      .includes(:logo_attachment)
      .reverse
      .find { |g| g.logo.attached? }
  end

  # Returns binary logo data.
  # Priority: group logo blob > Settings.application.logo file from webpack build.
  def logo_blob
    if logo_group
      logo_group.logo.blob.download
    else
      settings_logo_blob
    end
  end

  # Returns an absolute URL for the logo (for use in wallet providers and PDF).
  # Priority: group logo blob URL > Settings.application.logo webpack path.
  def logo_url
    if logo_group
      Rails.application.routes.url_helpers.rails_blob_url(logo_group.logo, only_path: false)
    else
      settings_logo_url
    end
  end

  # Returns a root-relative path suitable for use in HTML (image_tag).
  # Uses the webpack asset path directly, avoiding the need for a full URL.
  def logo_path
    if logo_group
      Rails.application.routes.url_helpers.rails_blob_path(logo_group.logo)
    else
      settings_logo_pack_path
    end
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

  # Resolve Settings.application.logo as a webpack asset path.
  def settings_logo_pack_path
    logo_image = Settings.application.logo&.image
    return nil if logo_image.blank?

    manifest = Webpacker.instance.manifest
    manifest.lookup("wagon-media/images/#{logo_image}") ||
      manifest.lookup("media/images/#{logo_image}")
  rescue Webpacker::Manifest::MissingEntryError
    nil
  end

  def settings_logo_url
    path = settings_logo_pack_path
    return nil unless path

    opts = Rails.application.routes.default_url_options.with_indifferent_access
    scheme = opts[:protocol] || "http"

    URI::Generic.build(scheme:, host: opts[:host], port: opts[:port], path:).to_s
  end

  # Read the Settings.application.logo file from the webpack build output.
  def settings_logo_blob
    path = settings_logo_pack_path
    return nil unless path

    # pack_path is relative (e.g. "/packs/media/images/logo-abc123.png").
    # Resolve to the file on disk via the public directory.
    file_path = Rails.public_path.join(path.delete_prefix("/"))
    File.binread(file_path) if File.exist?(file_path)
  end

  # Determines if the background color is light or dark based on luminance
  # @return [Boolean] true if background is light, false if dark
  def light_background?
    ColorLuminance.light?(pdf_background_color)
  end
end
