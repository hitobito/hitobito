# == Schema Information
#
# Table name: phone_numbers
#
#  id               :integer          not null, primary key
#  contactable_id   :integer          not null
#  contactable_type :string(255)      not null
#  number           :string(255)      not null
#  label            :string(255)
#  public           :boolean          default(TRUE), not null
#

class PhoneNumber < ActiveRecord::Base
  
  PREDEFINED_LABELS = %w(private mobile work father mother fax other)
  
  attr_accessible :number, :label, :public
  
  belongs_to :contactable, polymorphic: true
  
  
  def to_s
    "#{number} (#{label})"
  end
end
