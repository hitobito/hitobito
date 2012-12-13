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

  include NormalizedLabels

  attr_accessible :name, :label, :public, as: [:default, :superior]

  belongs_to :contactable, polymorphic: true

  validates_presence_of :label

  class << self
    def load_available_labels
      Settings.social_account.predefined_labels | super
    end
  end

  def to_s
    "#{name} (#{label})"
  end

  def value
    name
  end

end
