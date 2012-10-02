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
  
  attr_accessible :label, :start_at, :finish_at
  
  belongs_to :event

  def to_s
    name = "#{start_at} - #{finish_at}"
    label? ? "#{label}: #{name}" : name
  end
  
end
