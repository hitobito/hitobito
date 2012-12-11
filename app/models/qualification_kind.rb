# == Schema Information
#
# Table name: qualification_kinds
#
#  id          :integer          not null, primary key
#  label       :string(255)      not null
#  validity    :integer
#  description :string(1023)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  deleted_at  :datetime
#

class QualificationKind < ActiveRecord::Base
  
  acts_as_paranoid
  extend Paranoia::RegularScope
  
  attr_accessible :label, :validity, :description
  
  
  ### ASSOCIATIONS
  
  has_many :qualifications
  
  
  has_and_belongs_to_many :event_kinds, join_table: 'event_kinds_qualification_kinds',
                                        class_name: 'Event::Kind',
                                        association_foreign_key: :event_kind_id
  has_and_belongs_to_many :preconditions, join_table: 'event_kinds_preconditions', 
                                          class_name: 'Event::Kind', 
                                          association_foreign_key: :event_kind_id
  has_and_belongs_to_many :prolongations, join_table: 'event_kinds_prolongations', 
                                          class_name: 'Event::Kind', 
                                          association_foreign_key: :event_kind_id
  
  ### INSTANCE METHODS
  
  def to_s
    label
  end
  
  # Soft destroy if events exist, otherwise hard destroy
  def destroy
    if qualifications.exists?
      super
    else
      destroy!
    end
  end
  
  
end
