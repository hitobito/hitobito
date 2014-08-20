# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Csv::People
  # adds social_accounts and company related attributes
  class PeopleFull < PeopleAddress

    def person_attributes
      Person.column_names.collect(&:to_sym) -
        Person::INTERNAL_ATTRS -
        [:picture, :primary_group_id] +
        [:roles]
    end

    def association_attributes
      account_labels(people.map(&:additional_emails).flatten, AdditionalEmail).merge(
        account_labels(people.map(&:phone_numbers).flatten, PhoneNumber)).merge(
        account_labels(people.map(&:social_accounts).flatten, SocialAccount)).merge(
        relation_kind_labels)
    end

    def relation_kind_labels
      different_kinds = people.map(&:relations_to_tails).flatten.collect(&:kind).uniq
      different_kinds.each_with_object({}) do |kind, obj|
        if kind.present?
          obj[:"people_relation_#{kind}"] = PeopleRelation.new(kind: kind).translated_kind
        end
      end
    end
  end
end
