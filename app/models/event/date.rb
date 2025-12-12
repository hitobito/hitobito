#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
class Event::Date < ActiveRecord::Base
  include DatetimeAttribute
  datetime_attr :start_at, :finish_at

  belongs_to :event, touch: true

  validates_by_schema
  validates :start_at, presence: true
  validate :assert_meaningful

  def duration
    @duration ||= Duration.new(start_at, finish_at, date_format: :with_day)
  end

  def to_s(_format = :default)
    label? ? "#{label}: #{duration}" : duration
  end

  def label_and_location
    [label, location].compact.reject(&:empty?).join(", ")
  end

  private

  def assert_meaningful
    unless duration.meaningful?
      errors.add(:finish_at, :not_after_start)
    end
  end
end
