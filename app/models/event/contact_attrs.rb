#  Copyright (c) 2025, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Event::ContactAttrs
  extend ActiveSupport::Concern

  included do
    class_attribute :mandatory_contact_attrs,
      :possible_contact_attrs,
      :possible_contact_associations

    self.mandatory_contact_attrs = [:email, :first_name, :last_name]

    self.possible_contact_attrs = [:first_name, :last_name, :nickname, :company_name, :email,
      :address_care_of, :street, :housenumber, :postbox, :zip_code, :town, :country,
      :gender, :birthday, :phone_numbers, :language]

    self.possible_contact_associations = [:additional_emails, :social_accounts]
  end

  def show_contact_attr_address
    (contact_attribute_keys & [:street, :housenumber]).any?
  end

  def show_contact_attr?(a)
    contact_attribute_keys.include?(a)
  end

  def required_contact_attr?(a)
    required = required_contact_attrs.map(&:to_sym) + self.class.mandatory_contact_attrs
    required.include?(a.to_sym)
  end

  def contact_attribute_keys
    self.class.possible_contact_attrs - hidden_contact_attrs.collect(&:to_sym)
  end
end
