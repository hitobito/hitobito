# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::ContactDetailsResource < ApplicationResource
  self.model = ::Event
  self.type = "event-contact-details"
  self.readable_class = EventReadables
  self.acceptable_scopes += %w[events]

  ADDRESS_ATTRS = [:address_care_of, :street, :housenumber, :postbox, :zip_code, :town,
    :country].freeze
  CONTACT_ACCOUNTS = [:additional_addresses, :additional_emails, :phone_numbers,
    :social_accounts].freeze

  def self.contact_attribute(name, type, **)
    attribute(name, type, **) { @object.contact.public_send(name) }
  end

  with_options writable: false, filterable: false, sortable: false do # rubocop:disable Metrics/BlockLength
    with_options readable: :name_visible? do
      contact_attribute :first_name, :string
      contact_attribute :last_name, :string
      contact_attribute :nickname, :string
      contact_attribute :company_name, :string if Person.used_attributes.include?(:company_name)
      contact_attribute :company, :boolean if Person.used_attributes.include?(:company)
    end

    attribute :picture, :string, readable: :picture_visible? do
      @object.contact.decorate.picture_full_url
    end

    with_options readable: :address_visible? do
      ADDRESS_ATTRS.each { |attr| contact_attribute attr, :string }
      attribute :additional_addresses, :array do
        @object.contact.additional_addresses.select(&:public).map do |address|
          {label: address.category_label, **address.slice(*ADDRESS_ATTRS)}
        end
      end
    end

    with_options readable: :email_visible? do
      contact_attribute :email, :string
      attribute :additional_emails, :array do
        @object.contact.additional_emails.select(&:public).map do |email|
          {label: email.category_label, email: email.email}
        end
      end
    end

    attribute :phone_numbers, :array, readable: :phone_number_visible? do
      @object.contact.phone_numbers.select(&:public).map do |number|
        {label: number.category_label, number: number.number}
      end
    end

    attribute :social_accounts, :array, readable: :social_account_visible? do
      @object.contact.social_accounts.select(&:public).map do |account|
        {label: account.category_label, name: account.name}
      end
    end
  end

  Event::ALLOWED_VISIBLE_CONTACT_ATTRIBUTES.each do |option|
    define_method(:"#{option}_visible?") { |event| event.contact_attribute_visible?(option) }
  end

  def base_scope
    super.where.not(contact_id: nil).includes(contact: [
      {picture_attachment: :blob},
      *CONTACT_ACCOUNTS.map { |accounts| {accounts => {category: :translations}} }
    ])
  end
end
