#  Copyright (c) 2012-2026, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: phone_numbers
#
#  id               :integer          not null, primary key
#  contactable_type :string           not null
#  label            :string
#  number           :string           not null
#  public           :boolean          default(TRUE), not null
#  category_id      :bigint           not null
#  contactable_id   :integer          not null
#
# Indexes
#
#  index_phone_numbers_on_category_id                          (category_id)
#  index_phone_numbers_on_contactable_id_and_contactable_type  (contactable_id,contactable_type)
#
class PhoneNumber < ActiveRecord::Base
  include ContactAccount

  self.ignored_columns += [FullTextSearchable::SEARCH_COLUMN]

  self.value_attr = :number

  class_attribute :home_category_keys, default: %w[landline].freeze
  class_attribute :mobile_category_keys, default: %w[mobile].freeze

  scope :with_category_key, ->(keys) {
    joins(:category).where(contact_account_categories: {key: keys})
  }
  scope :home, -> { with_category_key(home_category_keys) }
  scope :mobile, -> { with_category_key(mobile_category_keys) }

  before_validation :format_number

  validates :number, phone: true

  validates_by_schema

  def home?
    home_category_keys.include?(category&.key)
  end

  def mobile?
    mobile_category_keys.include?(category&.key)
  end

  private

  def format_number
    phone = Phonelib.parse(number)
    if phone.valid?
      self.number = phone.international
    end
  end
end
