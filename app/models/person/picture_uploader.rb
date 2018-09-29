# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::PictureUploader < Uploader::Base

  MAX_DIMENSION = 8000

  self.allowed_extensions = %w(jpg jpeg gif png)

  include CarrierWave::MiniMagick

  # Process files as they are uploaded:
  process :validate_dimensions
  process :fix_exif_rotation
  process resize_to_fill: [72, 72]

  # Create different versions of your uploaded files:
  version :thumb do
    process resize_to_fill: [32, 32]
  end


  # Provide a default URL as a default if there hasn't been a file uploaded:
  def default_url
    ActionController::Base.helpers.asset_path(png_name)
  end

  def png_name
    ['profil', version_name].compact.join('_') + '.png'
  end

  private

  # check for images that are larger than you probably want
  def validate_dimensions
    manipulate! do |img|
      if img.dimensions.any? { |i| i > MAX_DIMENSION }
        fail CarrierWave::ProcessingError,
             I18n.t('errors.messages.dimensions_too_large', maximum: MAX_DIMENSION)
      end
      img
    end
  end

  def fix_exif_rotation
    manipulate! do |img|
      img.auto_orient
      img
    end
  end

end
