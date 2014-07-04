# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: event_dates
#
#  id        :integer          not null, primary key
#  event_id  :integer          not null
#  label     :string(255)
#  start_at  :datetime
#  finish_at :datetime
#  location  :string(255)
#

class Event::Date < ActiveRecord::Base

  include DatetimeAttribute
  datetime_attr :start_at, :finish_at

  belongs_to :event

  validates :start_at, presence: true
  validate :assert_meaningful


  def duration
    @duration ||= Duration.new(start_at, finish_at)
  end

  def to_s(_format = :default)
    label? ? "#{label}: #{duration}" : duration
  end

  def label_and_location
    [label, location].compact.reject(&:empty?).join(', ')
  end

  private

  def assert_meaningful
    unless duration.meaningful?
      errors.add(:finish_at,  :not_after_start)
    end
  end
end
