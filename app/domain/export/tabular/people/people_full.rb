#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Tabular::People
  class PeopleFull < PeopleAddress
    self.row_class = PersonRow
    self.styled_attrs = {
      date: [:birthday]
    }

    def person_attributes
      super +
        (Person.column_names.collect(&:to_sym) -
          Person::INTERNAL_ATTRS -
          excluded_person_attributes +
          [:layer_group, :roles, :tags] - super)
    end

    def excluded_person_attributes
      [:picture, :primary_group_id, :id]
    end

    def association_attributes
      contact_account_attributes.merge(qualification_kind_attributes)
    end

    def contact_account_attributes
      account_attribute_types.each_with_object({}) do |type, result|
        result.merge!(label_attributes_for(type))
      end
    end

    def account_attribute_types
      [AdditionalEmail, PhoneNumber, SocialAccount].tap do |types|
        types << AdditionalAddress if FeatureGate.enabled?("additional_address")
      end
    end

    def qualification_kind_attributes
      model = QualificationKind
      qualification_kinds = QualificationKind
        .joins(qualifications: :person)
        .includes(:translations)
        .where(people: {id: people_ids}).distinct
      qualification_kinds.each_with_object({}) do |qualification_kind, obj|
        label = qualification_kind.label
        obj[ContactAccounts.key(model, qualification_kind.id.to_s)] =
          ContactAccounts.human(model, label)
      end
    end
  end
end
