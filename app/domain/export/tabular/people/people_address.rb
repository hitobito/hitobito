#  Copyright (c) 2012-2026, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Tabular::People
  class PeopleAddress < Export::Tabular::Base
    self.model_class = ::Person
    self.row_class = PublicPersonRow

    private

    def person_attributes
      [:first_name, :last_name, :nickname, :company_name, :company, :email,
        :address_care_of, :street, :housenumber, :postbox, :zip_code, :town, :country, :layer_group,
        :roles]
    end

    def association_attributes
      contact_account_attributes
    end

    def contact_account_attributes
      account_attribute_types.each_with_object({}) do |model, result|
        result.merge!(label_attributes_for(model))
      end
    end

    def account_attribute_types
      [AdditionalEmail, PhoneNumber]
    end

    def label_attributes_for(model)
      contact_account_categories[model].transform_values do |category|
        ContactAccounts.human(model, category)
      end
    end

    # Resolved once per export and shared with every row (see #row_for), so a
    # large export doesn't re-query ContactAccountCategory per row per column.
    def contact_account_categories
      @contact_account_categories ||=
        ContactAccounts.categories_by_key(account_attribute_types, Person.sti_name)
    end

    def row_for(entry, format = nil)
      row = super
      row.contact_account_categories = contact_account_categories
      row
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
      # rubocop:todo Layout/LineLength
      when ActiveRecord::Relation then list.unscope(:order).unscope(:select).pluck(id_with_optional_table)
        # rubocop:enable Layout/LineLength
      end
    end
  end
end
