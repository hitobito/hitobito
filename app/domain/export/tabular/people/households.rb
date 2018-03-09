# encoding: utf-8
#  Copyright (c) 2012-2018, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Tabular::People
  class Households < Export::Tabular::Base

    self.model_class = ::Person
    self.row_class = HouseholdRow

    def initialize(list)
      @list = aggregate(list)
    end

    def person_attributes
      [:name, :address, :zip_code, :town, :country, :layer_group]
    end

    def build_attribute_labels
      person_attribute_labels
    end

    def person_attribute_labels
      person_attributes.each_with_object({}) do |attr, hash|
        hash[attr] = attribute_label(attr)
      end
    end

    def aggregate(list)
      list = add_household_key(list)
      people_memo = build_memo(list)

      people_memo.collect do |key, people|
        next people if key.blank?
        first_name, last_name = join_names(people)
        [assign(people.first, first_name, last_name)]
      end.flatten
    end

    def add_household_key(list)
      return list unless list.respond_to?(:unscoped)
      list = list.includes(:primary_group)
      list.to_sql =~ /people\.\*|household_key/ ? list : list.select('household_key')
    end

    def assign(person, first_name, last_name)
      person.first_name = first_name
      person.last_name = last_name
      person
    end

    def build_memo(list)
      list.inject(Hash.new { |h,k| h[k] = [] }) do |memo, person|
        memo[person.household_key] << person
        memo
      end
    end

    def join_names(people)
      people.collect do |person|
        [person.first_name, person.last_name]
      end.transpose.collect do |list|
        list.join(',')
      end
    end

  end
end
