# == Schema Information
#
# Table name: social_accounts
#
#  id               :integer          not null, primary key
#  contactable_id   :integer          not null
#  contactable_type :string(255)      not null
#  name             :string(255)      not null
#  label            :string(255)
#  public           :boolean          default(TRUE), not null
#

class SocialAccount < ActiveRecord::Base
  
  PREDEFINED_LABELS = %w(Skype MSN Website)
  
  attr_accessible :name, :label, :public
  
  belongs_to :contactable, polymorphic: true
  
  
  def to_s
    "#{name} (#{label})"
  end
end
