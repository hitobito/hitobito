# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::GuestResource < ApplicationResource
  self.type = :event_guests

  with_options writable: false, filterable: false, sortable: false do
    attribute :first_name, :string
    attribute :last_name, :string
    attribute :nickname, :string
    attribute :company_name, :string if Person.used_attributes.include? :company_name
    attribute :company, :boolean if Person.used_attributes.include? :company
    attribute :email, :string
    attribute :address_care_of, :string
    attribute :street, :string
    attribute :housenumber, :string
    attribute :postbox, :string
    attribute :zip_code, :string
    attribute :town, :string
    attribute :country, :string
    attribute :language, :string
    attribute :phone_number, :string
  end

  # NOTE: only sideloaded (via participations) therefore no explicit accessible_by necessary
  def base_scope = Event::Guest.all
end
