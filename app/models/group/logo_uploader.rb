#  Copyright (c) 2019, Schweizer Blasmusikverband. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Group::LogoUploader < Uploader::Base

  MAX_DIMENSION = 8000

  self.allowed_extensions = %w(jpg jpeg gif png svg)

  include CarrierWave::MiniMagick

  # Process files as they are uploaded:
  process :validate_dimensions, if: :processable?
  process resize_and_pad: [Settings.application.logo.width, Settings.application.logo.height], 
            if: :processable?

  # Provide a default URL as a default if there hasn't been a file uploaded:
  def default_url
    ActionController::Base.helpers.asset_path(Settings.application.logo.image)
  end

  private

  def processable?(file)
    file.content_type.match?('^image/') && !(file.content_type.match?('^image/svg'))
  end 

  # check for images that are larger than you probably want
  def validate_dimensions
    manipulate! do |img|
      if img.dimensions.any? { |i| i > MAX_DIMENSION }
        raise CarrierWave::ProcessingError,
              I18n.t('errors.messages.dimensions_too_large', maximum: MAX_DIMENSION)
      end
      img
    end
  end
end
