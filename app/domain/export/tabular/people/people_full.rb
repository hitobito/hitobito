#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Tabular::People
  class PeopleFull < PeopleAddress
    def person_attributes
      Person.column_names.collect(&:to_sym) -
        Person::INTERNAL_ATTRS -
        excluded_person_attributes +
        [:layer_group, :roles, :tags]
    end

    def excluded_person_attributes
      [:picture, :primary_group_id, :id]
    end

    def association_attributes
      account_labels(AdditionalEmail)
        .merge(account_labels(PhoneNumber))
        .merge(account_labels(SocialAccount))
        .merge(qualification_kinds)
        .merge(relation_kind_labels)
    end

    def qualification_kinds
      model = QualificationKind
      labels = QualificationKind
        .joins(qualifications: :person).where(people: {id: people_ids})
        .joins(:translations).distinct.pluck(:label)
      labels.each_with_object({}) do |label, obj|
        obj[ContactAccounts.key(model, label)] = ContactAccounts.human(model, label)
      end
    end

    def relation_kind_labels
      kinds = PeopleRelation.where(head_id: people_ids).distinct.pluck(:kind)

      kinds.each_with_object({}) do |kind, obj|
        if kind.present?
          obj[:"people_relation_#{kind}"] = PeopleRelation.new(kind: kind).translated_kind
        end
      end
    end
  end
end
