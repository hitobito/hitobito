# == Schema Information
#
# Table name: event_dates
#
#  id        :integer          not null, primary key
#  event_id  :integer          not null
#  label     :string(255)
#  start_at  :datetime
#  finish_at :datetime
#

class Event::Date < ActiveRecord::Base
  
  attr_accessible :label,
                  :start_at, :start_at_min, :start_at_h, :start_at_date,
                  :finish_at, :finish_at_min, :finish_at_h, :finish_at_date
  
  belongs_to :event

  before_validation :merge_start_at, :merge_finish_at

  def start_at_date
    @start_at_date ||= start_at.try(:to_date)
  end

  def start_at_h
    @start_at_h ||= start_at.try(:hour)
  end

  def start_at_min
    @start_at_min ||= start_at.try(:min)
  end

  def finish_at_date
    @finish_at_date ||= finish_at.try(:to_date)
  end

  def finish_at_h
    @finish_at_h ||= finish_at.try(:hour)
  end

  def finish_at_min
    @finish_at_min ||= finish_at.try(:min)
  end

  def start_at_date=(value)
    start_at_will_change! unless value == start_at_date
    @start_at_date = value
  end

  def start_at_h=(value)
    start_at_will_change! unless value == start_at_h
    @start_at_h = value
  end

  def start_at_min=(value)
    start_at_will_change! unless value == start_at_min
    @start_at_min = value
  end

  def finish_at_date=(value)
    finish_at_will_change! unless value == finish_at_date
    @finish_at_date = value
  end

  def finish_at_h=(value)
    finish_at_will_change! unless value == finish_at_h
    @finish_at_h = value
  end

  def finish_at_min=(value)
    finish_at_will_change! unless value == finish_at_min
    @finish_at_min = value
  end

  def duration
    @duration ||= Duration.new(start_at, finish_at)
  end

  def to_s
    label? ? "#{label}: #{duration}" : duration
  end
  
  private
  def merge_start_at
    if @start_at_date.present?
      date = start_at_date.to_date
      self.start_at = merge_date_time(date, start_at_h, start_at_min)
    end
  end

  def merge_finish_at
    if @finish_at_date.present?
      date = finish_at_date.to_date
      self.finish_at = merge_date_time(date, finish_at_h, finish_at_min)
    end
  end

  def merge_date_time(date,h,min)
    h = h.blank? ? 00 : h
    min = min.blank? ? 00 : min
    Time.zone.local(date.year, date.month, date.day, h.to_i, min.to_i)
  end

end
