# frozen_string_literal: true

#  Copyright (c) 2022-2025,  Eidgenössischer Jodlerverband. This file is part of
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
#  housenumber           :string(20)
#  invoices              :boolean          default(FALSE), not null
#  label                 :string           not null
#  name                  :string           not null
#  postbox               :string
#  public                :boolean          default(FALSE), not null
#  street                :string           not null
#  town                  :string           not null
#  uses_contactable_name :boolean          default(TRUE), not null
#  zip_code              :string           not null
#  contactable_id        :bigint
#
# Indexes
#
#  idx_on_contactable_id_contactable_type_invoices_45d4363dd7  (contactable_id,contactable_type,invoices) UNIQUE WHERE (invoices = true)
#  idx_on_contactable_id_contactable_type_label_53043e4f10     (contactable_id,contactable_type,label) UNIQUE
#  index_additional_addresses_on_contactable                   (contactable_type,contactable_id)
#

Fabricator(:additional_address) do
  contactable { Fabricate(:person) }
  street { Faker::Address.street_name }
  housenumber { Faker::Address.building_number }
  zip_code { Faker::Address.zip_code }
  town { Faker::Address.city }
  country { Faker::Address.country_code }
  label { AdditionalAddress.predefined_labels.first }
end
