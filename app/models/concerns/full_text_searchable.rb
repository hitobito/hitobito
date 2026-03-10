#  Copyright (c) 2012-2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module FullTextSearchable
  extend ActiveSupport::Concern

  SEARCH_COLUMN = :search_column
  SUPPORTED_LANGUAGES = {
    de: "german",
    fr: "french",
    it: "italian",
    en: "english",
    _: "simple"
  }.with_indifferent_access.tap { |s| s.default = "simple" }

  included do
    self.ignored_columns += [SEARCH_COLUMN]
  end

  module ClassMethods
    def search(term)
      associated_tables = self::SEARCHABLE_ATTRS.select { |attr| attr.is_a?(Hash) }
        .map(&:keys).flatten
      tables = [table_name] + associated_tables

      select(column_names, "GREATEST(#{tsquery_search_ranks(tables, term)}) AS rank")
        .left_joins(tsquery_join_tables(associated_tables))
        .where(tsquery_search_conditions(tables, term))
        .order("rank DESC")
        .distinct
    end

    private

    # Returns SQL to generate a tsquery expression for searching. This supports:
    # - Associative search, i.e. every word from the query must be present in the results.
    #   websearch_to_tsquery inserts the operator & in between all normal search terms.
    # - Prefix search, i.e. every word in the query can also match if it is only a prefix
    #   of a word in the result.
    #   We acheive this by appending :* to every quoted query word.
    # - Quoting multiple words in the search query to only match results which contain
    #   this word sequence, e.g. the search term `for search` will match the text
    #   `search for`, but the search term `"for search"` with quotes will not.
    # - Querying e.g. by `termA OR termB` will match both the text `terma` and the text
    #   `termb`.
    # - Excluding search terms by adding a dash in front of them. E.g. the query
    #   `foo -bar` will match the text `foo baz` but not the text `foo bar baz`.
    # - Language-dependent word stemming and stopwords. E.g. when using the application
    #   in French, the query `la matinée der` is automatically changed as if it were
    #   `matin der`, but if using the application in German, it's changed to mean
    #   `la matiné`, and in English it's `la matiné der`.
    # - Automatically removing special characters from the search terms.
    def tsquery(term)
      ActiveRecord::Base.sanitize_sql_array([
        <<~SQL.squish,
          replace(
            websearch_to_tsquery(:lang, :term)::text || ' ',
            ''' ',
            ''':* '
          )::tsquery
        SQL
        term: term,
        lang: tsquery_lang
      ])
    end

    # Returns the ts_config name which most closely matches the current application language.
    # The ts_config contains word stemming rules and word ignore rules.
    def tsquery_lang
      # PostgreSQL supports a large range of languages out of the box. This here is just a
      # selection of the ones most relevant to our application. To list all supported configs,
      # run `\dF` or `select * from pg_catalog.pg_ts_config;` in the psql client.

      SUPPORTED_LANGUAGES[I18n.locale || :simple]
    end

    def tsquery_search_ranks(tables, term)
      tables.map do |table|
        "COALESCE(ts_rank(#{table}.#{SEARCH_COLUMN}, #{tsquery(term)}), 0)"
      end.join(", ")
    end

    def tsquery_search_conditions(tables, term)
      tables.map do |table|
        "#{table}.#{SEARCH_COLUMN} @@ #{tsquery(term)}"
      end.join(" OR ")
    end

    def tsquery_join_tables(tables)
      tables.map do |table|
        if table.to_s.end_with?("_translations")
          intermediate = table.to_s.gsub(/_translations$/, "").pluralize.to_sym
          if table_name.to_sym == intermediate
            :translations
          else
            [intermediate, intermediate => :translations]
          end
        else
          table
        end
      end.flatten
    end
  end
end
