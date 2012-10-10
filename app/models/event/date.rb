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
  
  attr_accessible :label, :start_at_date, :start_at_h, :start_at_min, :start_at, :finish_at
  attr_writer :start_at_date, :start_at_h, :start_at_min
  attr_accessor :finish_at_date, :finish_at_h, :finish_at_min
  
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

  private
  def merge_start_at
    if start_at_date.present?
      date = start_at_date.to_date
      self.start_at = merge_date_time(date, start_at_h, start_at_min)
    end
  end

  def merge_finish_at
    if finish_at_date.present?
      date = finish_at_date.to_date
      self.finish_at = merge_date_time(date, finish_at_h, finish_at_min)
    end
  end

  def merge_date_time(date,h,min)
    h = h.blank? ? 00 : h
    min = min.blank? ? 00 : min
    DateTime.new(date.year, date.month, date.day, h.to_i, min.to_i)
  end

  def to_s
    name = "#{start_at} - #{finish_at}"
    label? ? "#{label}: #{name}" : name
  end
  
end
