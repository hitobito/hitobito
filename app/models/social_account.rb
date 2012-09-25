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

  before_save :normalize_labels

  class << self
    def available_labels
      @available_labels ||= Settings.social_account.predefined_labels |
      order(:label).uniq.pluck(:label).compact
    end
    
    def sweep_available_labels
      @available_labels = nil
    end
  end 

  def to_s
    "#{name} (#{label})"
  end
  
  def value
    name
  end
  
  private
  
  # If a case-insensitive same label already exists, use this one
  def normalize_labels
    return if label.blank?
    
    fresh = self.class.available_labels.none? do |l|
      equal = l.casecmp(label) == 0
      self.label = l if equal
      equal
    end
    self.class.sweep_available_labels if fresh
  end
end
