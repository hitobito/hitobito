# frozen_string_literal: true

#  Copyright (c) 2012-2021, Pfadibewegung Schweiz. This file is part of
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
      [:salutation, :name, :address, :zip_code, :town, :country, :layer_group]
    end

    def build_attribute_labels
      person_attribute_labels
    end

    def person_attribute_labels
      person_attributes.index_with { |attr| attribute_label(attr) }
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

      list.unscope(:select)
          .only_public_data
          .select('household_key')
          .includes(:primary_group)
    end

    def build_memo(list)
      list.each_with_object(Hash.new { |h, k| h[k] = [] }) do |person, memo|
        memo[person.household_key] << person
      end
    end

    def join_names(people)
      people
        .collect { |person| [person.first_name, person.last_name] }
        .transpose
        .collect { |list| list.join(',') }
    end

    def assign(person, first_name, last_name)
      person.first_name = first_name
      person.last_name = last_name
      person
    end

  end
end
