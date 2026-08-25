# frozen_string_literal: true

#  Copyright (c) 2022-2026,  Eidgenössischer Jodlerverband. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: additional_addresses
#
#  id                    :bigint           not null, primary key
#  address_care_of       :string
#  contactable_type      :string
#  country               :string           not null
#  first_name            :string
#  housenumber           :string(20)
#  invoices              :boolean          default(FALSE), not null
#  label                 :string           not null
#  last_name             :string
#  organization          :boolean          default(FALSE), not null
#  organization_name     :string
#  postbox               :string
#  public                :boolean          default(FALSE), not null
#  street                :string           not null
#  town                  :string           not null
#  uses_contactable_name :boolean          default(TRUE), not null
#  zip_code              :string           not null
#  category_id           :bigint           not null
#  contactable_id        :bigint
#
# Indexes
#
#  index_additional_addresses_on_category_id                      (category_id)
#  index_additional_addresses_on_contactable                      (contactable_type,contactable_id)
#  index_additional_addresses_on_contactable_where_invoices_true  (contactable_id,contactable_type) UNIQUE WHERE (invoices = true)
#
class AdditionalAddress < ApplicationRecord
  include ContactAccount
  include PostalAddress

  # Aliases so business logic outside this model can treat AdditionalAddress like Person,
  # without needing to know about the organization/organization_name columns.
  alias_attribute :company, :organization
  alias_attribute :company_name, :organization_name

  validates_by_schema
  validates :organization_name, presence: {if: :organization?}
  validate :assert_has_any_name

  belongs_to :location, foreign_key: "zip_code", primary_key: "zip_code", inverse_of: false

  before_validation :copy_name_from_contactable, if: :uses_contactable_name

  def self.predefined_labels
    Settings.additional_address.predefined_labels
  end

  def name
    if organization? && organization_name.present?
      organization_name
    else
      full_name
    end
  end

  def full_name
    [first_name, last_name].compact_blank.join(" ").presence
  end

  def to_s = value

  def value
    street_with_number = [street, housenumber].compact_blank.join(" ")
    town_with_zipcode = [zip_code, town].compact_blank.join(" ")

    [
      name,
      address_care_of,
      street_with_number,
      postbox.presence,
      town_with_zipcode,
      (country_label unless ignored_country?)
    ].compact_blank.join(", ")
  end

  private

  def copy_name_from_contactable
    if contactable.is_a?(Group)
      copy_name_from_group
    else
      copy_name_from_person
    end
  end

  def copy_name_from_person
    self.first_name = contactable.first_name
    self.last_name = contactable.last_name
    self.organization_name = contactable.company_name
    self.organization = contactable.company
  end

  def copy_name_from_group
    self.organization_name = contactable.to_s
    self.organization = true
    self.first_name = nil
    self.last_name = nil
  end

  def assert_has_any_name
    if !organization? && first_name.blank? && last_name.blank?
      errors.add(:base, :name_missing)
    end
  end
end
