# encoding: utf-8

#  Copyright (c) 2015, Pro Natura Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::AttachmentUploader < CarrierWave::Uploader::Base

  EXTENSION_WHITE_LIST = Settings.event.attachments.file_extensions.split(/\s+/)

  # Choose what kind of storage to use for this uploader:
  storage :file

  class << self
    def accept_extensions
      EXTENSION_WHITE_LIST.collect { |e| ".#{e}" }.join(', ')
    end
  end

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  def extension_white_list
    EXTENSION_WHITE_LIST
  end

end
