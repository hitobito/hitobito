class Event::Course::Condition < ActiveRecord::Base
  attr_accessible :content, :group_id, :label
  belongs_to :group


  def to_s
    label
  end
end
