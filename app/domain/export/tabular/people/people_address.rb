#  Copyright (c) 2012-2024, Jungwacht Blauring Schweiz. This file is part of
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
      label_attributes_for(AdditionalEmail).merge(label_attributes_for(PhoneNumber))
    end

    def label_attributes_for(model)
      predefined_label_attributes(model).merge(custom_label_attributes(model))
    end

    def predefined_label_attributes(model)
      ContactAccounts.predefined_labels(model).each_with_object({}) do |label, result|
        result[ContactAccounts.key(model, label)] =
          ContactAccounts.human(model, model.translate_label(label))
      end
    end

    def custom_label_attributes(model)
      return {} unless ContactAccounts.custom_label_enabled?(model)

      {ContactAccounts.custom_label_key(model) => ContactAccounts.custom_label_human(model)}
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
