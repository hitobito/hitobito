#  Copyright (c) 2012-2024, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module SearchStrategies
  class PersonSearch < Base

    # rubocop:disable Metrics/MethodLength
    def search_fulltext
      return no_people unless term_present?

      pg_rank_alias = extract_pg_ranking(Person.search(@term).to_sql)

      search_results = if date_query?(@term)
        Person.search(reformat_date(@term))
      else
        Person.search(@term)
      end

      entries = search_results
                  .accessible_by(PersonReadables.new(@user))
                  .select(pg_rank_alias) # add pg_search rank to select list of base query again

      people_without_role = index_people_without_role?(search_results)
      entries += people_without_role if people_without_role

      entries += Group::DeletedPeople.deleted_for_multiple(
        deleted_people_indexable_layers
      ) & search_results

      entries.uniq
    end
    # rubocop:enable Metrics/MethodLength

    private

    def index_people_without_role?(search_results)
      if Ability.new(@user).can?(:index_people_without_role, Person)
        search_results.where('NOT EXISTS (SELECT * FROM roles ' \
                    "WHERE (roles.deleted_at IS NULL OR
                            roles.deleted_at > :now) AND
                          roles.person_id = people.id)", now: Time.now.utc.to_s(:db))
      end
    end

    def no_people
      Person.none.page(1)
    end

    def deleted_people_indexable_layers
      accessible_layers.select do |layer|
        Ability.new(@user).can?(:index_deleted_people, layer)
      end
    end

    # extract first order by value to reselect in permission checked query
    def extract_pg_ranking(query)
      match = query.match(/ORDER BY (\w+\.\w+)/)
      return match[1] if match
      nil
    end

    def reformat_date(date_str)
      possible_formats = ["%d.%m.%Y", "%d.%m", "%d-%m-%Y", "%d-%m"]
      formatted_date = nil

      possible_formats.each do |format|
        begin
          date = Date.strptime(date_str, format)
          formatted_date = date.strftime("%Y-%m-%d")
          break
        rescue ArgumentError
          next
        end
      end

      if has_year?(date_str)
        formatted_date
      else
        formatted_date.slice(4..-1)
      end
    end

    def has_year?(date_string)
      /\b\d{4}\b/.match?(date_string)
    end

    def date_query?(date_query)
      /\A\d{2}[.-]\d{2}([.-]\d{4})?\z/.match?(date_query)
    end
  end
end
