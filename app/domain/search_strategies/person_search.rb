#  Copyright (c) 2012-2024, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module SearchStrategies
  class PersonSearch < Base
    POSSIBLE_DATE_FORMATS = ["%d.%m.%Y", "%d.%m", "%d-%m-%Y", "%d-%m"].freeze
    REGULAR_DATE_FORMAT = "%Y-%m-%d"

    self.model_class = Person
    self.readables_ability = PersonReadables

    private

    def accessible_scope
      scopes = [super, people_without_role, deleted_people].compact
      if scopes.size == 1
        scopes.first
      else
        arel_union = scopes
          .map { |scope| scope.reselect("people.id").arel }
          .reduce { |memo, node| Arel::Nodes::Union.new(memo, node) }
        Person.where(Person.arel_table[:id].in(Arel::Nodes::Grouping.new(arel_union)))
      end
    end

    def people_without_role
      return unless ability.can?(:index_people_without_role, Person)

      Person.where(
        <<-SQL,
          NOT EXISTS (
            SELECT * FROM roles
            WHERE (roles.end_on IS NULL OR roles.end_on >= :today) AND
                  roles.person_id = people.id
          )
        SQL
        today: Date.current.to_fs(:db)
      )
    end

    def deleted_people
      layers = deleted_people_indexable_layers
      return if layers.blank?

      Group::DeletedPeople.deleted_for_multiple(layers)
    end

    def deleted_people_indexable_layers
      accessible_layers.select do |layer|
        ability.can?(:index_deleted_people, layer)
      end
    end

    def accessible_layers
      @user.groups.flat_map(&:layer_hierarchy)
    end

    def ability
      @ability ||= Ability.new(@user)
    end

    # extract first order by value to reselect in permission checked query
    def extract_pg_ranking(query)
      match = query.match(/ORDER BY (\w+\.\w+)/)
      return match[1] if match
      nil
    end

    def normalized_term
      @normalized_term ||= normalized_date_term
    end

    def normalized_date_term
      return @term unless date_term?

      formatted_date = formatted_date_term

      # when the date could not be formatted it is likely that the user entered an impossible date
      # like 43.15.3912
      return @term if formatted_date.nil?

      if term_has_year?
        formatted_date
      else
        formatted_date.slice(4..-1)
      end
    end

    def formatted_date_term
      POSSIBLE_DATE_FORMATS.each do |format|
        date = Date.strptime(@term, format)
        return date.strftime(REGULAR_DATE_FORMAT)
      rescue ArgumentError
      end
      nil
    end

    def term_has_year?
      /\b\d{4}\b/.match?(@term)
    end

    def date_term?
      /\A\d{2}[.-]\d{2}([.-]\d{4})?\z/.match?(@term)
    end
  end
end
