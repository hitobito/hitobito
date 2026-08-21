# frozen_string_literal: true

#  Copyright (c) 2025-2026, BdP and DPSG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AdditionalAddressResource < ApplicationResource
  include ContactAccountResource

  attribute :first_name, :string
  attribute :last_name, :string
  attribute :organization_name, :string
  attribute :organization, :boolean
  attribute :address_care_of, :string
  attribute :street, :string
  attribute :housenumber, :string
  attribute :postbox, :string
  attribute :zip_code, :string
  attribute :town, :string
  attribute :country, :string
end
