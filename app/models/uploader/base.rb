# encoding: utf-8

#  Copyright (c) 2012-2017, hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Uploader::Base < CarrierWave::Uploader::Base
  class_attribute :allowed_extensions

  # Choose what kind of storage to use for this uploader
  storage :file

  class << self
    def accept_extensions
      allowed_extensions.collect { |e| ".#{e}" }.join(", ")
    end
  end

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  def extension_whitelist
    allowed_extensions
  end

  def base_store_dir
    "uploads"
  end

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    "#{base_store_dir}/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end
end
