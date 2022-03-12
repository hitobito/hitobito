# frozen_string_literal: true

#  Copyright (c) 2012-2021, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Tabular::People
  class Households < Export::Tabular::Base

    self.model_class = ::Person
    self.row_class = HouseholdRow

    def person_attributes
      [:salutation, :name, :address, :zip_code, :town, :country, :layer_group]
    end

    def build_attribute_labels
      person_attribute_labels
    end

    def person_attribute_labels
      person_attributes.index_with { |attr| attribute_label(attr) }
    end

    def list
      @household_list ||= begin # rubocop:disable Naming/MemoizedInstanceVariableName @list is already used in the base-class, which shadows this extension
        people = super
        people = Person.where(id: people) unless people.respond_to?(:only_public_data)

        People::HouseholdList.new(people.only_public_data.includes(:primary_group))
      end
    end

  end
end
