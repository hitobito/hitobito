# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class FullTextController < ApplicationController

  skip_authorization_check

  helper_method :entries

  respond_to :html

  def index
    @people = if params[:q].to_s.size >= 2
                PaginatingDecorator.decorate(list_people)
              else
                Kaminari.paginate_array([]).page(1)
              end
    respond_with(@people)
  end

  def query
    people = query_people.collect { |i| PersonDecorator.new(i).as_quicksearch }
    groups = query_groups.collect { |i| GroupDecorator.new(i).as_quicksearch }
    events = query_events.collect { |i| EventDecorator.new(i).as_quicksearch }

    render json: results_with_separator(people, groups, events) || []
  end

  private

  def list_people
    return Person.none.page(1) unless params[:q].present?
    query_accessible_people do |ids|
      entries = fetch_people(ids)
      entries = Person::PreloadGroups.for(entries)
      entries = Person::PreloadPublicAccounts.for(entries)
      entries
    end
  end

  def fetch_people(ids)
    Person.search(Riddle::Query.escape(params[:q]),
                  page: params[:page],
                  order: 'last_name asc, ' \
                         'first_name asc, ' \
                         "#{ThinkingSphinx::SphinxQL.weight[:select]} desc",
                  star: true,
                  with: { sphinx_internal_id: ids })
  end

  def query_people
    return Person.none.page(1) unless params[:q].present?
    query_accessible_people do |ids|
      Person.search(Riddle::Query.escape(params[:q]),
                    per_page: 10,
                    star: true,
                    with: { sphinx_internal_id: ids })
    end
  end

  def query_accessible_people
    ids = accessible_people_ids
    return Person.none.page(1) if ids.blank?
    yield ids
  end

    def query_groups
    return Person.none.page(1) unless params[:q].present?
    Group.search(Riddle::Query.escape(params[:q]),
                 per_page: 10,
                 star: true,
                 include: :parent)
  end

  def query_events
    return Person.none.page(1) unless params[:q].present?
    Event.search(Riddle::Query.escape(params[:q]),
                 per_page: 10,
                 star: true,
                 include: :groups)
  end

  def accessible_people_ids
    key = "accessible_people_ids_for_#{current_user.id}"
    Rails.cache.fetch(key, expires_in: 15.minutes) do
      ids = load_accessible_people_ids
      ids += load_deleted_people_ids if can?(:index_people_without_role, Person)
      ids.uniq
    end
  end

  def load_accessible_people_ids
    accessible = Person.accessible_by(PersonReadables.new(current_user))

    # This still selects all people attributes :(
    # accessible.pluck('people.id')

    # rewrite query to only include id column
    sql = accessible.to_sql.gsub(/SELECT (.+) FROM /, 'SELECT DISTINCT people.id FROM ')
    result = Person.connection.execute(sql)
    result.collect { |row| row[0] }
  end

  def load_deleted_people_ids
    Person.where('NOT EXISTS (SELECT * FROM roles ' \
                 'WHERE roles.deleted_at IS NULL AND roles.person_id = people.id)').
           pluck(:id)
  end

  def results_with_separator(*sets)
    sets.select(&:present?).inject do |memo, set|
      memo + [{ label: '—' * 20 }] + set
    end
  end

  def entries
    @people
  end
end
