#  Copyright (c) 2012-2024, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module PgSearchable
  def self.included(model)
    model.include PgSearch::Model


    model.pg_search_scope :search,
      against: model.const_defined?(:SEARCHABLE_ATTRS) ? 
                model::SEARCHABLE_ATTRS.select { |element| element.is_a?(Symbol) } : 
                [],
      associated_against: model.const_defined?(:SEARCHABLE_ATTRS) ? 
                          model::SEARCHABLE_ATTRS.select { |element| element.is_a?(Hash) }.first : 
                          [],
      using: {
        tsearch: { prefix: true }
      }
  end
end