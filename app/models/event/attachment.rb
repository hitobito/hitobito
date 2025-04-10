# frozen_string_literal: true

#  Copyright (c) 2015-2024, Pro Natura Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: event_attachments
#
#  id         :integer          not null, primary key
#  visibility :string
#  event_id   :integer          not null
#
# Indexes
#
#  index_event_attachments_on_event_id  (event_id)
#

class Event::Attachment < ActiveRecord::Base
  MAX_FILE_SIZE = Settings.event.attachments.max_file_size.megabytes
  CONTENT_TYPES = Settings.event.attachments.content_types

  belongs_to :event

  VISIBILITIES = ["team", "participants", "global"].freeze
  enum visibility: VISIBILITIES.zip(VISIBILITIES).to_h

  # this could become a has_many_attached on Event
  has_one_attached :file

  validates_by_schema
  validates :visibility, inclusion: {in: VISIBILITIES.map(&:to_s), allow_nil: true}
  validates :file, size: {less_than_or_equal_to: MAX_FILE_SIZE},
    content_type: CONTENT_TYPES

  scope :list, -> { attached.order("active_storage_blobs.filename") }
  scope :attached, -> { joins(:file_blob) }
  scope :visible_for_team, -> { where(visibility: [:team, :participants, :global]) }
  scope :visible_for_participants, -> { where(visibility: [:participants, :global]) }
  scope :visible_globally, -> { where(visibility: :global) }

  def to_s
    file
  end

  def remove_file
    false
  end

  def remove_file=(deletion_param)
    if %w[1 yes true].include?(deletion_param.to_s.downcase) && file.persisted?
      file.purge_later
    end
  end
end
