# frozen_string_literal: true

#  Copyright (c) 2015-2022, Pro Natura Schweiz. This file is part of
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

class Event::Attachment < ActiveRecord::Base

  MAX_FILE_SIZE = Settings.event.attachments.max_file_size.megabytes
  CONTENT_TYPES = Settings.event.attachments.content_types

  belongs_to :event

  mount_uploader :carrierwave_file, Event::AttachmentUploader, mount_on: 'file'
  # this could become a has_many_attached on Event
  has_one_attached :file

  validates_by_schema except: :file
  if ENV['NOCHMAL_MIGRATION'].blank? # if not migrating RIGHT NOW, i.e. normal case
    validates :file, size: { less_than_or_equal_to: MAX_FILE_SIZE },
                     content_type: CONTENT_TYPES
  end

  scope :list, -> { order(:file) }

  def to_s
    file
  end

  def remove_file
    false
  end

  def remove_file=(delete_it)
    file.purge_later if delete_it
  end

end
