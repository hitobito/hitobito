# == Schema Information
#
# Table name: event_kinds
#
#  id          :integer          not null, primary key
#  label       :string(255)      not null
#  short_name  :string(255)
#  minimum_age :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  deleted_at  :datetime
#

class Event::Kind < ActiveRecord::Base
  
  acts_as_paranoid
  
  
  attr_accessible :label, :short_name, :minimum_age
  
  has_many :events
  
  has_and_belongs_to_many :qualification_types, join_table: 'event_kinds_qualification_types',
                                                foreign_key: :event_kind_id
  has_and_belongs_to_many :preconditions, join_table: 'event_kinds_preconditions', 
                                          class_name: 'QualificationType', 
                                          foreign_key: :event_kind_id
  has_and_belongs_to_many :prolongations, join_table: 'event_kinds_prolongations', 
                                          class_name: 'QualificationType', 
                                          foreign_key: :event_kind_id

  ### INSTANCE METHODS
  def to_s
    "#{short_name} ( #{label} )"
  end
  
  # Soft destroy if events exist, otherwise hard destroy
  def destroy
    if events.exists?
      super
    else
      destroy!
    end
  end
  
end
