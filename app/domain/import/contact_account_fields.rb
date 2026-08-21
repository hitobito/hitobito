#  Copyright (c) 2012-2026, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Import
  class ContactAccountFields < SimpleDelegator
    attr_reader :prefix, :human, :model

    def initialize(model)
      @prefix = model.model_name.to_s.underscore
      @human = model.model_name.human
      @model = model

      super(map_category_fields.with_indifferent_access)
    end

    def fields
      map { |key, value| {key: key, value: value} }
    end

    def key_for(category)
      "#{prefix}_#{category.key}".downcase
    end

    def category_for(key)
      categories.find { |category| key_for(category) == key }
    end

    private

    def map_category_fields
      categories.each_with_object({}) do |category, hash|
        hash[key_for(category)] = "#{human} #{category}"
      end
    end

    def categories
      @categories ||= ContactAccountCategory.for(model.sti_name, ::Person.sti_name).to_a
    end
  end
end
