# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
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

  include ContactAccount

  self.value_attr = :number

  before_validation :format_number

  validates :number, phone: true

  validates_by_schema

  private

  def format_number
    phone = Phonelib.parse(self.number)
    if phone.valid?
      self.number = phone.international
    end
  end

  class << self
    def predefined_labels
      Settings.phone_number.predefined_labels
    end
  end

end
