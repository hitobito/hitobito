# == Schema Information
#
# Table name: event_kinds
#
#  id         :integer          not null, primary key
#  label      :string(255)      not null
#  short_name :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  deleted_at :datetime
#

class Event::Kind < ActiveRecord::Base
  
  acts_as_paranoid
  
  
  attr_accessible :label, :short_name
  
  has_many :events

  ### INSTANCE METHODS
  def to_s
    "#{short_name} ( #{label} )"
  end
  
  
end
