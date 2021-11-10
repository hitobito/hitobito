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

  def people_without_household
    @people_scope.where(household_key: nil)
  end

  def grouped_households
    people = Person.quoted_table_name

    @people_scope.
        # remove previously added selects, very important to make this query scale
        unscope(:select, :includes).
        # group by household, but keep NULLs separate
        select("IFNULL(#{people}.`household_key`, #{people}.`id`) as `key`").
        group(:key).
        # Primary sorting criterion
        select("COUNT(#{people}.`household_key`) as `member_count`").
        # Secondary, unique sorting criterion
        select("MIN(#{people}.`id`) as `id`")
  end

  def households_in_batches(exclude_non_households: false)
    return unless block_given?
    base_scope = exclude_non_households ? only_households : grouped_households

    in_batches(base_scope, batch_size: 300) do |batch|
      involved_people = fetch_people_with_id_or_household_key(batch.map(&:key))
      grouped_people = batch.map do |household|
        involved_people.select do |person|
          # the 'key' is either a household key or a single person id
          person.household_key == household.key || person.id.to_s == household.key
        end
      end
      yield grouped_people
    end
  end

  def each(exclude_non_households: false, &block)
    return to_enum(:each) unless block_given?

    households_in_batches(exclude_non_households: exclude_non_households) do |batch|
      batch.each(&block)
    end
  end

  private

  def only_households
    grouped_households.where.not(household_key: nil)
  end

  def fetch_people_with_id_or_household_key(keys_or_ids)
    # Search for any number of housemates, regardless of preview limit
    base_scope = @people_scope.unscope(:limit)
    # Make sure to select household_key if we aren't selecting specific columns
    base_scope = base_scope.select(:household_key) if base_scope.select_values.present?

    base_scope.where(household_key: keys_or_ids).
        or(base_scope.where(id: keys_or_ids)).
        load
  end

  # Copied and adapted from ActiveRecord::Batches#in_batches
  # We need to order and "offset" the batches by two separate columns, which
  # activerecord doesn't support natively. Activerecord only supports ordering by the
  # primary key column and doesn't use SQL OFFSET internally, for performance reasons:
  # https://github.com/rails/rails/pull/20933
  # rubocop:disable Metrics/MethodLength this is a close copy of a rails method
  def in_batches(base_scope, batch_size: 1000)
    relation = base_scope

    batch_limit = batch_size
    if base_scope.limit_value
      remaining   = base_scope.limit_value
      batch_limit = remaining if remaining < batch_limit
    end

    relation = relation.reorder('`member_count` DESC, id ASC').limit(batch_limit)
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

        if remaining == 0
          # Saves a useless iteration when the limit is a multiple of the batch size.
          break
        elsif remaining < batch_limit
          relation = relation.limit(remaining)
        end
      end

      batch_relation = relation.having('`member_count` < ? OR (`member_count` = ? AND `id` > ?)',
                                       member_count_offset, member_count_offset, id_offset)
    end
  end

end
