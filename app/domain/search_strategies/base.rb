# frozen_string_literal: true

#  Copyright (c) 2017, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module SearchStrategies
  class Base

    QUERY_PER_PAGE = 10

    attr_accessor :term

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

    def query_addresses
      # override
      Address.none.page(1)
    end

    def query_invoices
      # override
      Invoice.none.page(1)
    end

    def inspect
      "<#{self.class.name}: term: #{@term.inspect}>"
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

        ids += load_accessible_deleted_people_ids

        ids.uniq
      end
    end

    def load_accessible_people_ids
      Person.accessible_by(PersonReadables.new(@user)).
        unscope(:select). # accessible_by selects all people attributes, even when using .pluck
        pluck(:id)
    end

    def load_deleted_people_ids
      Person.where('NOT EXISTS (SELECT * FROM roles ' \
                   "WHERE (roles.deleted_at IS NULL OR
                           roles.deleted_at > :now) AND
                          roles.person_id = people.id)", now: Time.now.utc.to_s(:db))
            .pluck(:id)
    end

    def load_accessible_deleted_people_ids
      Group::DeletedPeople.deleted_for_multiple(deleted_people_indexable_layers).pluck(:id)
    end

    def deleted_people_indexable_layers
      accessible_layers.select do |layer|
        Ability.new(@user).can?(:index_deleted_people, layer)
      end
    end

    def accessible_layers
      @user.groups.flat_map(&:layer_hierarchy)
    end
  end
end
