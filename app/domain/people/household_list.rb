# frozen_string_literal: true

#  Copyright (c) 2012-2021, Die Mitte Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class People::HouseholdList
  include Enumerable

  def initialize(people_scope)
    @people_scope = people_scope
  end

  def only_households_in_batches
    return unless block_given?

    fetch_in_batches(only_households) { |batch| yield batch }
  end

  def people_without_household_in_batches
    return unless block_given?

    fetch_in_batches(people_without_household) { |batch| yield batch }
  end

  def households_in_batches
    return unless block_given?

    fetch_in_batches(grouped_households) { |batch| yield batch }
  end

  def grouped_households
    Person.from("((#{only_households.unscope(:limit).to_sql}) " \
                    "UNION ALL (#{people_without_household.unscope(:limit).to_sql})) " \
                    "#{people_table}").limit(@people_scope.limit_value.presence)
  end

  def each(&block)
    return to_enum(:each) unless block

    households_in_batches do |batch|
      batch.each(&block)
    end
  end

  private

  def fetch_in_batches(scope) # rubocop:disable Metrics/MethodLength,Metrics/CyclomaticComplexity
    in_batches(scope, batch_size: 300) do |batch|
      involved_people = fetch_involved_people(batch.map(&:key))
      grouped_people = batch.map do |household|
        involved_people.select do |person|
          # the 'key' is either a household key or a single person id
          person.household_key == household.key || person.id.to_s == household.key.to_s
        end
      end
      yield grouped_people
    end
  end

  def only_households
    base_scope
      .select(:household_key)
      .select("MIN(#{people_table}.`id`) as `id`")
      .select("COUNT(#{people_table}.`household_key`) as `member_count`")
      .select("#{people_table}.`household_key` as `key`")
      .where.not(household_key: nil)
      .group(:household_key)
  end

  def people_without_household
    base_scope
      .select(:household_key)
      .select(:id)
      .select("1 as `member_count`")
      .select("#{people_table}.`id` as `key`")
      .where(household_key: nil)
      .order(:id)
  end

  def people_table
    Person.quoted_table_name
  end

  def base_scope
    # Remove preview limit for fetching all candidate ids, and re-apply it afterwards.
    # This way, we can add more conditions to the query builder while keeping the performance
    # benefits of pre-calculating the candidate id list.
    @base_scope ||= Person
      .where(id: @people_scope.unscope(:select, :includes, :limit).pluck(:id))
      .limit(@people_scope.limit_value.presence)
  end

  def fetch_involved_people(ids_or_household_keys)
    # Search for any number of housemates, regardless of preview limit
    base_scope = @people_scope.unscope(:limit)
    # Make sure to select household_key if we aren't selecting specific columns
    base_scope = base_scope.select(:household_key) if base_scope.select_values.present?

    base_scope.where(household_key: ids_or_household_keys)
      .or(base_scope.where(id: ids_or_household_keys))
      .load
  end

  # Copied and adapted from ActiveRecord::Batches#in_batches
  # We need to order and "offset" the batches by two separate columns, which
  # activerecord doesn't support natively. Activerecord only supports ordering by the
  # primary key column and doesn't use SQL OFFSET internally, for performance reasons:
  # https://github.com/rails/rails/pull/20933
  def in_batches(base_scope, batch_size: 1000) # rubocop:disable Metrics/MethodLength,Metrics/CyclomaticComplexity,Metrics/AbcSize,Metrics/PerceivedComplexity this is a close copy of a rails method
    relation = base_scope

    batch_limit = batch_size
    if base_scope.limit_value
      remaining = base_scope.limit_value
      batch_limit = remaining if remaining < batch_limit
    end

    relation = relation.reorder("`member_count` DESC, id ASC").limit(batch_limit)
    # Retaining the results in the query cache would undermine the point of batching
    relation.skip_query_cache!
    batch_relation = relation

    loop do
      records = batch_relation.records
      ids = records.map(&:id)
      yielded_relation = base_scope.where(id: ids)
      yielded_relation.send(:load_records, records)

      break if ids.empty?

      member_count_offset = records.last.member_count
      id_offset = ids.last

      yield yielded_relation

      break if ids.length < batch_limit

      if base_scope.limit_value
        remaining -= ids.length

        if remaining.zero?
          # Saves a useless iteration when the limit is a multiple of the batch size.
          break
        elsif remaining < batch_limit
          relation = relation.limit(remaining)
        end
      end

      batch_relation = relation.where("`member_count` < ? OR (`member_count` = ? AND `id` > ?)",
        member_count_offset, member_count_offset, id_offset)
    end
  end
end
