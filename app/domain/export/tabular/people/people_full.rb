#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Tabular::People
  class PeopleFull < PeopleAddress
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
      account_labels(AdditionalEmail)
        .merge(account_labels(PhoneNumber))
        .merge(account_labels(SocialAccount))
        .merge(account_labels(AdditionalAddress))
        .merge(qualification_kinds)
    end

    def qualification_kinds
      model = QualificationKind
      qualification_kinds = QualificationKind
        .joins(qualifications: :person)
        .includes(:translations)
        .where(people: {id: people_ids}).distinct
      qualification_kinds.each_with_object({}) do |qualification_kind, obj|
        label = qualification_kind.label_translations.values.join(" / ")
        obj[ContactAccounts.key(qualification_kind, qualification_kind.id.to_s)] = ContactAccounts.human(model, label)
      end
    end
  end
end
