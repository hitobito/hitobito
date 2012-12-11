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
  extend Paranoia::RegularScope
  
  attr_accessible :label, :short_name, :minimum_age, :qualification_kind_ids, :precondition_ids, :prolongation_ids

  
  ### ASSOCIATIONS
  
  has_many :events
  
  # The qualifications to gain for this event kind
  has_and_belongs_to_many :qualification_kinds, join_table: 'event_kinds_qualification_kinds',
                                                foreign_key: :event_kind_id
  # The qualifications required to visit this event kind
  has_and_belongs_to_many :preconditions, join_table: 'event_kinds_preconditions', 
                                          class_name: 'QualificationKind', 
                                          foreign_key: :event_kind_id
  # The qualifications that are prolonged when visiting this event kind
  has_and_belongs_to_many :prolongations, join_table: 'event_kinds_prolongations', 
                                          class_name: 'QualificationKind', 
                                          foreign_key: :event_kind_id


  ### INSTANCE METHODS
  
  def to_s
    "#{short_name} (#{label})"
  end
  
  # is this event type qualifying
  def qualifying?
    qualification_kinds.exists? || prolongations.exists?
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
