#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Tabular::People
  class PeopleAddress < Export::Tabular::Base
    self.model_class = ::Person
    self.row_class = PersonRow

    private

    def person_attributes
      [:first_name, :last_name, :nickname, :company_name, :company, :email,
        :address, :zip_code, :town, :country, :layer_group, :roles]
    end

    def association_attributes
      account_labels(AdditionalEmail.where(public: true)).merge(
        account_labels(PhoneNumber.where(public: true))
      )
    end

    def account_labels(collection)
      scope = collection.distinct_on(:label)
      model = scope.model
      scope.map(&:translated_label).uniq.each_with_object({}) do |label, obj|
        if label.present?
          obj[ContactAccounts.key(model, label)] = ContactAccounts.human(model, label)
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
  end
end
