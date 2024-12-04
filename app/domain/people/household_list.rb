# frozen_string_literal: true

#  Copyright (c) 2012-2021, Die Mitte Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class People::HouseholdList
  BATCH_SIZE = 300

  include Enumerable

  def initialize(people_scope, order: :member_count)
    @people_scope = people_scope
    @order = order
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
    person_ids_grouped_by_household_query(@people_scope).count
  end

  delegate :each, :each_with_index, :map, :to_a, to: :households_in_batches

  private

  def in_batches(people_scope, batch_size: BATCH_SIZE)
    return to_enum(:in_batches, people_scope, batch_size: batch_size) unless block_given?

    # load complete list of ids to retain order
    person_ids = person_ids_grouped_by_household_query(people_scope).map(&:person_ids)
    person_ids.each_slice(batch_size) do |batch|
      # index involved_people for quicker access
      involved_people = Person.where(id: batch.flatten).index_by(&:id)
      batch.map do |household|
        yield household.map { |person_id| involved_people[person_id] }
      end
    end
  end

  # create a virtual column with the array position in the underlying @people_scope
  # to be able to sort by this column
  def computed_ordinal_column(scope)
    ids = scope.unscope(:limit).pluck(:id)
    ArelArrayLiteral.new(ids).array_position(Person.arel_table[:id]) if ids.present?
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
    ids, household_keys = scope.unscope(:select, :includes, :limit, :order).pluck(:id, :household_key).transpose

    Person.arel_table
      .where(Person.arel_table[:id].in(ids).or(Person.arel_table[:household_key].in(household_keys.uniq.compact)))
      .project(Person.arel_table[:id].as("person_id"))
      .project(household_key_column.as("household_key"))
      .project(ordinal_column.as("ordinal"))
      .order(ordinal_column.alias)
  end

  def person_ids_grouped_by_household_query(scope)
    return Person.none if scope.none?

    ordered_households_table = Arel::Nodes::TableAlias.new(ordered_computed_household_key_query(scope), "ordered_keys")
    order_statement = (@order == :retain) ? ordered_households_table[:ordinal].minimum : "member_count DESC"
    aggregated_person_ids_column = Arel::Nodes::NamedFunction.new("ARRAY_AGG", [ordered_households_table[:person_id]])

    x = Person
      .from(ordered_households_table)
      .select(Arel.star.count.as("member_count"))
      .select(aggregated_person_ids_column.as("person_ids"))
      .group(ordered_households_table[:household_key])
      .order(order_statement)
      # existing behaviour: apply limit to households, not to people
      .limit(scope.limit_value.presence)
    Rails.logger.info x.to_sql
    x
  end
end
