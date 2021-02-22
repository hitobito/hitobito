#  Copyright (c) 2015, Pro Natura Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
# == Schema Information
#
# Table name: event_attachments
#
#  id       :integer          not null, primary key
#  file     :string(255)      not null
#  event_id :integer          not null
#
# Indexes
#
#  index_event_attachments_on_event_id  (event_id)
#

class Event::Attachment < ApplicationRecord
  MAX_FILE_SIZE = Settings.event.attachments.max_file_size.megabytes

  belongs_to :event

  mount_uploader :file, Event::AttachmentUploader

  validates_by_schema except: :file
  validate :assert_file_size

  scope :list, -> { order(:file) }

  def to_s
    file
  end

  private

  def assert_file_size
    if file.size.to_f > MAX_FILE_SIZE
      errors.add(:file, :filesize_too_large, maximum: MAX_FILE_SIZE / 1.megabyte)
    end
  end
end
