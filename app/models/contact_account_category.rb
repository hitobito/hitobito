# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: contact_account_categories
#
#  id                     :bigint           not null, primary key
#  contact_account_type   :string           not null
#  contactable_type       :string           not null
#  key                    :string           not null
#  position               :integer          default(0), not null
#  unique_per_contactable :boolean          default(FALSE), not null
#  used_for_invoices      :boolean          default(FALSE), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_contact_account_categories_on_type_and_key  (contact_account_type,contactable_type,key) UNIQUE
#
class ContactAccountCategory < ApplicationRecord
  include Globalized

  CONTACT_ACCOUNT_TYPES = [AdditionalAddress, AdditionalEmail, PhoneNumber, SocialAccount]
  CONTACTABLE_TYPES = [Person, Group]
  OTHER_KEY = "other"

  self.list_alphabetically = false
  self.default_list_order = [:contactable_type, :contact_account_type, :position]

  translates :name

  validates :name, presence: true
  validates :key, presence: true,
    uniqueness: {scope: [:contact_account_type, :contactable_type]}

  validates :contact_account_type, presence: true,
    inclusion: {in: CONTACT_ACCOUNT_TYPES.map(&:sti_name)}

  validates :contactable_type, presence: true, inclusion: {in: CONTACTABLE_TYPES.map(&:sti_name)}

  validate :assert_used_for_invoices_implies_unique_per_contactable

  attr_readonly :key, :contact_account_type, :contactable_type

  scope :used_for_invoices, -> { where(used_for_invoices: true) }
  scope :other, -> { where(key: OTHER_KEY) }

  def self.for(contact_account_type, contactable_type)
    with_translation
      .where(contact_account_type: contact_account_type, contactable_type: contactable_type)
      .order(:position)
  end

  def other?
    key == OTHER_KEY
  end

  def to_s
    name
  end

  private

  def assert_used_for_invoices_implies_unique_per_contactable
    return unless used_for_invoices? && !unique_per_contactable?

    errors.add(:unique_per_contactable, :required_when_used_for_invoices,
      attribute: self.class.human_attribute_name(:used_for_invoices))
  end
end
