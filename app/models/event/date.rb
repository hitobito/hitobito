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
  
  include DatetimeAttribute
  datetime_attr :start_at, :finish_at
  
  attr_accessible :label
  
  belongs_to :event

  def duration
    @duration ||= Duration.new(start_at, finish_at)
  end

  def to_s
    label? ? "#{label}: #{duration}" : duration
  end

end
