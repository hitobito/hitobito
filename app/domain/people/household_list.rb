# frozen_string_literal: true

#  Copyright (c) 2012-2021, Die Mitte Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class People::HouseholdList
  BATCH_SIZE = 300

  include Enumerable

  def initialize(people_scope, retain_order: false, include_housemates: false)
    @people_scope = people_scope
    @retain_order = retain_order
    @include_housemates = include_housemates
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

  def count
    return [] if @people_scope.none?

    person_ids_grouped_by_household_query(@people_scope).to_a.size
  end

  delegate :each, :each_with_index, :map, :to_a, to: :find_each

  def find_each(batch_size: BATCH_SIZE, &)
    return to_enum(:find_each, batch_size: batch_size) unless block_given?

    in_batches(@people_scope, batch_size: batch_size) do |batch|
      batch.each do |household|
        yield household
      end
    end
  end

  private

  def in_batches(people_scope, batch_size: BATCH_SIZE)
    return to_enum(:in_batches, people_scope, batch_size: batch_size) unless block_given?
    return if people_scope.none?

    # load complete list of ids to retain order
    person_ids = person_ids_grouped_by_household_query(people_scope).map(&:person_ids)
    person_ids.each_slice(batch_size) do |batch|
      # index involved_people for quicker access
      involved_people = Person.where(id: batch.flatten).index_by(&:id)
      batch_with_households = batch.map { |household| household.map { |person_id| involved_people[person_id] } }
      yield batch_with_households
    end
  end

  # create a virtual column with the array position in the underlying @people_scope
  # to be able to sort by this column
  def computed_ordinal_column(scope)
    person_ids = scope.unscope(*[:limit, (:order unless @retain_order)].compact).pluck(:id)
    ArelArrayLiteral.new(person_ids).array_position(Person.arel_table[:id]) if person_ids.present?
  end

  # create a virtual column with household_key OR _person_id to be able
  # to group by this column
  def computed_household_key_column
    Arel::Nodes::NamedFunction.new("COALESCE", [
      Person.arel_table[:household_key],
      Arel::Nodes::NamedFunction.new("FORMAT", [Arel::Nodes.build_quoted("_%s"), Person.arel_table[:id]])
      # compare performance
      # [Person.arel_table[:id].cast(:text)])
    ])
  end

  # create a virtual table with computed household_key and ordinal colums to be able
  # to sort and group the result
  def ordered_computed_household_key_query(scope)
    ordinal_column = computed_ordinal_column(scope)
    household_key_column = computed_household_key_column
    unscoped = scope.unscope(:select, :includes, :limit, :order)
    ids = unscoped.pluck(:id)
    household_keys = @include_housemates ? unscoped.pluck(:household_key) : []

    Person.arel_table
      .where(Person.arel_table[:id].in(ids).or(Person.arel_table[:household_key].in(household_keys.uniq.compact)))
      .project(Person.arel_table[:id].as("person_id"))
      .project(household_key_column.as("household_key"))
      .project(ordinal_column.as("ordinal"))
      .order(ordinal_column.alias)
  end

  def person_ids_grouped_by_household_query(scope)
    ordered_households_table = Arel::Nodes::TableAlias.new(ordered_computed_household_key_query(scope), "ordered_keys")
    aggregated_person_ids_column = Arel::Nodes::NamedFunction.new("ARRAY_AGG", [ordered_households_table[:person_id]])
    order_statement = @retain_order ? ordered_households_table[:ordinal].minimum : "member_count DESC"

    Person
      .from(ordered_households_table)
      .select(Arel.star.count.as("member_count"))
      .select(aggregated_person_ids_column.as("person_ids"))
      .group(ordered_households_table[:household_key])
      .order(order_statement)
      .limit(scope.limit_value.presence) # existing behaviour: apply limit to households, not to people
  end
end
