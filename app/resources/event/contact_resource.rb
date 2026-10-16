# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::ContactResource < ApplicationResource
  self.type = "event-contact"
  self.model = Event::Contact

  CONTACT_ATTRS = {
    name: [:first_name, :last_name, :nickname, :company_name, :company],
    address: [:address, :address_care_of, :street, :housenumber, :postbox, :zip_code, :town,
      :country],
    email: [:email],
    picture: [:picture]
  }.freeze

  with_options writable: false, filterable: false, sortable: false,
    readable: :contact_attribute_visible? do
    attribute :first_name, :string
    attribute :last_name, :string
    attribute :nickname, :string
    attribute :company_name, :string if Person.used_attributes.include? :company_name
    attribute :company, :boolean if Person.used_attributes.include? :company
    attribute :email, :string
    attribute :address, :string
    attribute :address_care_of, :string
    attribute :street, :string
    attribute :housenumber, :string
    attribute :postbox, :string
    attribute :zip_code, :string
    attribute :town, :string
    attribute :country, :string
    attribute :picture, :string do
      @object.decorate.picture_full_url
    end
  end

  with_options writable: false, filterable: false, sortable: false do
    attribute :household_key, :string
    attribute :primary_group_id, :integer
    attribute :language, :string
    attribute :updated_at, :datetime
  end

  def self.assign_visibility(events, contacts)
    contacts.each do |contact|
      contact.visible_contact_attributes = events
        .select { |event| event.contact_id == contact.id }
        .map { |event| event.visible_contact_attributes.map(&:to_s) }
        .reduce(Event::ALLOWED_VISIBLE_CONTACT_ATTRIBUTES, :&)
    end
  end

  # Only sideloaded via events, which define the visibility of the contact attributes
  def base_scope = Event::Contact.all

  private

  def contact_attribute_visible?(contact, attribute)
    key = CONTACT_ATTRS.find { |_key, attrs| attrs.include?(attribute.to_sym) }&.first
    contact.contact_attribute_visible?(key)
  end
end
