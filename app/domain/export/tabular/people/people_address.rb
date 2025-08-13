#  Copyright (c) 2012-2024, Jungwacht Blauring Schweiz. This file is part of
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
        :address_care_of, :street, :housenumber, :postbox, :zip_code, :town, :country, :layer_group,
        :roles]
    end

    def association_attributes
      account_labels(AdditionalEmail.where(public: true)).merge(
        account_labels(PhoneNumber.where(public: true))
      )
    end

    def account_labels(collection)
      scope = collection
        .where(contactable_id: people_ids, contactable_type: Person.sti_name)
        .distinct_on(:label)
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

    def people_ids
      @people_ids ||= pluck_ids_from_list("people.id")
    end

    def pluck_ids_from_list(id_with_optional_table, list = @list)
      case list
      when Array then list.pluck(id_with_optional_table.to_s.split(".").last)
      when ActiveRecord::Relation then list.unscope(:order).unscope(:select).pluck(id_with_optional_table)
      end
    end
  end
end
