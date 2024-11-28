# frozen_string_literal: true

#  Copyright (c) 2012-2021, Die Mitte Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class People::HouseholdList
  BATCH_SIZE = 300

  include Enumerable

  def initialize(people_scope, order: :default)
    @people_scope = people_scope
  end

  def only_households_in_batches(&)
    in_batches(@people_scope.where.not(household_key: nil), &)
  end

  def people_without_household_in_batches(&)
    in_batches(@people_scope.where(household_key: nil), &)
  end

  def households_in_batches(&)
    in_batches(@people_scope, &)
  end

  delegate :each, :map, :to_a, to: :households_in_batches

  private

  def in_batches(people_scope, batch_size: BATCH_SIZE)
    return to_enum(:in_batches, people_scope, batch_size: batch_size) unless block_given?

    # load complete list of ids to retain order
    person_ids = person_ids_grouped_by_household_query(people_scope).map(&:person_ids)
    person_ids.each_slice(batch_size) do |batch|
      involved_people = Person.where(id: batch.flatten).index_by(&:id)
      batch.map do |household|
        yield household.map { |person_id| involved_people[person_id] }
      end
    end
  end

  def computed_ordinal_column(people_scope)
    ids_in_order = ArelArrayLiteral.new(people_scope.unscope(:limit, :select).pluck(:id))
    Arel::Nodes::NamedFunction.new("ARRAY_POSITION", [ids_in_order.to_sql, Person.arel_table[:id]])
  end

  def computed_household_key_column
    Arel::Nodes::NamedFunction.new("COALESCE", [
      Person.arel_table[:household_key],
      Arel::Nodes::NamedFunction.new("FORMAT", [Arel::Nodes.build_quoted("_%s"), Person.arel_table[:id]])
      # compare performance
      # [Person.arel_table[:id].cast(:text)])
    ])
  end

  def ordered_computed_household_key_query(people_scope)
    ordinal_column = computed_ordinal_column(people_scope)
    household_key_column = computed_household_key_column

    Person.arel_table
      .where(Person.arel_table[:id].in(people_scope.unscope(:select, :includes, :limit, :order).pluck(:id)))
      .project(Person.arel_table[:id].as("person_id"))
      .project(household_key_column.as("household_key"))
      .project(ordinal_column.as("ordinal"))
      .order(ordinal_column.alias)
    # apply limit to people, not to households
    # .take(people_scope.limit_value.presence)
  end

  def person_ids_grouped_by_household_query(people_scope)
    ordered_keys = Arel::Nodes::TableAlias.new(ordered_computed_household_key_query(people_scope), "ordered_keys")

    Person
      .from(ordered_keys)
      .select(Arel.star.count.as("member_count"))
      .select(Arel::Nodes::NamedFunction.new("ARRAY_AGG", [ordered_keys[:person_id]]).as("person_ids"))
      .group(ordered_keys[:household_key])
      .order(ordered_keys[:ordinal].minimum)
      # apply limit to households?
      .limit(people_scope.limit_value.presence)
  end
end
