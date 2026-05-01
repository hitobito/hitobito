# frozen_string_literal: true

#  Copyright (c) 2012-2024, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module SearchStrategies
  class Base
    class_attribute :model_class, :readables_ability

    # Hash of identifier attributes and regular expressions to match them,
    # e.g. { number: /\A\d+\z/ }
    # If the search term matches one of the regular expressions,
    # the record with the given attribute value will be prepended to the search results.
    # Identifier attribute columns should have a database index.
    class_attribute :searchable_identifiers
    self.searchable_identifiers = {}

    attr_accessor :term

    def initialize(user, term, page, limit: nil)
      @user = user
      @term = term
      @page = page
      @limit = limit
    end

    def search
      identifier_results = search_identifiers.to_a
      if identifier_results.present?
        identifier_results + search_fulltext.excluding(identifier_results)
      else
        search_fulltext
      end
    end

    def search_fulltext
      accessible_scope.search(@term).limit(@limit)
    end

    def search_identifiers
      identifiers = matching_identifiers
      return model_class.none if identifiers.blank?

      condition = identifiers.map do |attribute|
        "#{model_class.table_name}.#{attribute} = :term"
      end.join(" OR ")
      accessible_scope.where(condition, term: @term)
    end

    protected

    def accessible_scope
      if readables_ability
        model_class.accessible_by(readables_ability.new(@user))
      else
        model_class.all
      end
    end

    def matching_identifiers
      searchable_identifiers.filter_map do |attribute, regex|
        attribute if @term.match?(regex)
      end
    end
  end
end
