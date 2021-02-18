# frozen_string_literal: true

#  Copyright (c) 2021, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class GroupSetting::LogoUploader < Uploader::Base

  MAX_DIMENSION = 8000

  self.allowed_extensions = %w(jpg jpeg gif png)

  include CarrierWave::MiniMagick

  # Process files as they are uploaded:
  process :validate_dimensions

  private

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
