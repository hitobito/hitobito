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
  
  attr_accessible :label, :location
  
  belongs_to :event
  
  validates :start_at, presence: true
  validate  :assert_meaningful
  

  def duration
    @duration ||= Duration.new(start_at, finish_at)
  end

  def to_s
    label? ? "#{label}: #{duration}" : duration
  end

  private
  
  def assert_meaningful
    unless duration.meaningful?
      errors.add(:finish_at, "muss nach Von liegen")
    end
  end
end
