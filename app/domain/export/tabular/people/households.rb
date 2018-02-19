# encoding: utf-8
#  Copyright (c) 2012-2018, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Tabular::People
  class Households < Export::Tabular::Base

    self.model_class = ::Person
    self.row_class = HouseholdRow

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

    def list
      super.group(:uniq_household_key).select(custom_select)
    end

    def custom_select
      <<-SQL
        group_concat(people.first_name) as first_name,
        group_concat(people.last_name) as last_name,
        people.address, people.town, people.zip_code, people.country,
        IFNULL(household_key,UUID()) as uniq_household_key
      SQL
    end
  end
end
