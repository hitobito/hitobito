# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

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

  validates :label, presence: true

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
