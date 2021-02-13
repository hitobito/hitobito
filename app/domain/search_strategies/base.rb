# encoding: utf-8

#  Copyright (c) 2017, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module SearchStrategies
  class Base

    QUERY_PER_PAGE = 10

    def initialize(user, term, page)
      @user = user
      @term = term
      @page = page
    end

    def list_people
      return Person.none.page(1) if @term.blank?
      query_accessible_people do |ids|
        entries = fetch_people(ids)
        entries = Person::PreloadGroups.for(entries)
        entries = Person::PreloadPublicAccounts.for(entries)
        entries
      end
    end

    def query_people
      # override
      Person.none.page(1)
    end

    def query_groups
      # override
      Group.none.page(1)
    end

    def query_events
      # override
      Event.none.page(1)
    end

    protected

    def fetch_people(_ids)
      # override
      Person.none.page(1)
    end

    def query_accessible_people
      ids = accessible_people_ids
      return Person.none.page(1) if ids.blank?
      yield ids
    end

    def accessible_people_ids
      key = "accessible_people_ids_for_#{@user.id}"
      Rails.cache.fetch(key, expires_in: 15.minutes) do
        ids = load_accessible_people_ids
        if Ability.new(@user).can?(:index_people_without_role, Person)
          ids += load_deleted_people_ids
        end
        ids.uniq
      end
    end

    def load_accessible_people_ids
      accessible = Person.accessible_by(PersonReadables.new(@user))

      # This still selects all people attributes :(
      # accessible.pluck('people.id')

      # rewrite query to only include id column
      sql = accessible.to_sql.gsub(/SELECT (.+) FROM /, "SELECT DISTINCT people.id FROM ")
      result = Person.connection.execute(sql)
      result.collect { |row| row[0] }
    end

    def load_deleted_people_ids
      Person.where("NOT EXISTS (SELECT * FROM roles " \
                   "WHERE roles.deleted_at IS NULL AND roles.person_id = people.id)")
            .pluck(:id)
    end

  end
end
