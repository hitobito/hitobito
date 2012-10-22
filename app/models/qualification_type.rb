# == Schema Information
#
# Table name: qualification_types
#
#  id          :integer          not null, primary key
#  label       :string(255)      not null
#  validity    :integer
#  description :string(1023)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  deleted_at  :datetime
#

class QualificationType < ActiveRecord::Base
  
  acts_as_paranoid
  
  attr_accessible :label, :validity, :description
  
  
  has_many :qualifications
  
  has_and_belongs_to_many :event_kinds
  
  
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
