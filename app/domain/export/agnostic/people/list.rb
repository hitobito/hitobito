# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Agnostic::People::List


  # Attributes of people we want to include

  private

  def person_attributes
    [:first_name, :last_name, :nickname, :company_name, :company, :email,
     :address, :zip_code, :town, :country, :gender, :birthday, :roles]
  end

  def association_attributes
    public_account_labels(:additional_emails, AdditionalEmail).merge(
      public_account_labels(:phone_numbers, PhoneNumber))
  end

  def public_account_labels(accounts, klass)
    account_labels(people.map(&accounts).flatten.select(&:public?), klass)
  end

  def account_labels(collection, model)
    collection.map(&:translated_label).uniq.each_with_object({}) do |label, obj|
      if label.present?
        obj[Export::Agnostic::People::ContactAccounts.key(model, label)] =
          Export::Agnostic::People::ContactAccounts.human(model, label)
      end
    end
  end

  def qualification_kind_labels(collection, model)
    collection.map(&:label).uniq.each_with_object({}) do |label, obj|
      if label.present?
        obj[Export::Agnostic::People::ContactAccounts.key(model, label)] = label
      end
    end
  end

  def build_attribute_labels
    person_attribute_labels.merge(association_attributes)
  end

  def person_attribute_labels
    person_attributes.each_with_object({}) do |attr, hash|
      hash[attr] = attribute_label(attr)
    end
  end

  def people
    list
  end

end
