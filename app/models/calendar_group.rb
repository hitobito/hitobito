# frozen_string_literal: true

#  Copyright (c) 2022, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class CalendarGroup < ActiveRecord::Base
  belongs_to :calendar
  belongs_to :group

  after_destroy :delete_calendar_if_no_included_groups_left

  scope :excluded, -> { where(excluded: true) }
  scope :included, -> { where(excluded: false) }

  validates :event_type, allow_blank: true, inclusion: { in: ->(entry) do
    entry.group.layer_group.event_types.map(&:to_s)
  end }

  def delete_calendar_if_no_included_groups_left
    calendar.destroy if calendar.reload.included_calendar_groups.count < 1
  end
end
