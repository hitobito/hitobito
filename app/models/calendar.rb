# frozen_string_literal: true

#  Copyright (c) 2022, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Calendar < ActiveRecord::Base

  belongs_to :group

  has_many :calendar_tags, inverse_of: :calendar, dependent: :destroy
  has_many :included_calendar_tags, -> { where(excluded: false) },
           inverse_of: :calendar, class_name: 'CalendarTag', dependent: :destroy
  has_many :excluded_calendar_tags, -> { where(excluded: true) },
           inverse_of: :calendar, class_name: 'CalendarTag', dependent: :destroy

  has_many :included_calendar_groups, -> { where(excluded: false) },
           inverse_of: :calendar, class_name: 'CalendarGroup', dependent: :destroy
  has_many :excluded_calendar_groups, -> { where(excluded: true) },
           inverse_of: :calendar, class_name: 'CalendarGroup', dependent: :destroy

  accepts_nested_attributes_for :included_calendar_tags, :excluded_calendar_tags,
                                :included_calendar_groups, :excluded_calendar_groups,
                                allow_destroy: true

  validates_by_schema except: [:token]
  validates :included_calendar_groups, presence: true

  scope :list, -> { order(:name) }

  before_create :generate_token

  def to_s(_format = :default)
    name
  end

  def included_calendar_tags_ids
    included_calendar_tags.map(&:tag).pluck(:id)
  end

  def excluded_calendar_tags_ids
    excluded_calendar_tags.map(&:tag).pluck(:id)
  end

  def path_args
    [group, self]
  end

  private

  def generate_token
    self.token = SecureRandom.urlsafe_base64
  end
end
