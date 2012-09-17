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
  
  attr_accessible :name, :label, :public, as: [:default, :superior]
  
  belongs_to :contactable, polymorphic: true

  class << self
    def available_labels
      Settings.social_account.predefined_labels |
      order(:label).uniq.pluck(:label)
    end
  end 

  def to_s
    "#{name} (#{label})"
  end
end
