#  Copyright (c) 2012-2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module FindableByOrderedIdList
  extend ActiveSupport::Concern

  included do
    unless self < ActiveRecord::Base
      raise "Module FindableByOrderedIdList can only be included in Active Record models"
    end
  end

  module ClassMethods
    def find_in_ordered_batches(ids, batch_size: 500)
      check_findable_by_id(__method__)

      batch_enumerator(ids, batch_size)
    end

    def find_by_ids_keeping_order(ids)
      check_findable_by_id(__method__)

      where(id: ids).order(Arel.sql(
        "array_position(ARRAY[?]::int[], #{table_name}.id)", ids
      ))
    end

    private

    def batch_enumerator(ids, batch_size)
      entry_count = ids.count
      iterated = false

      enumerator = Enumerator.new(entry_count) do |yielder|
        raise_if_already_iterated!(iterated)
        iterated = true

        ids.each_slice(batch_size) do |id_batch|
          find_by_ids_keeping_order(id_batch).each do |entry|
            yielder << entry
          end
        end
      end

      enumerator.define_singleton_method(:count) { entry_count }

      enumerator
    end

    def raise_if_already_iterated!(iterated)
      return unless iterated

      raise "This batch enumerator (from find_in_ordered_batches) can only be iterated " \
        "once. It was already consumed, so calling #each/#map/#pluck/#to_a etc. again " \
        "would re-run every underlying query instead of reusing the previous result. " \
        "Fetch and memoize whatever you need during the first pass."
    end

    def check_findable_by_id(method)
      unless column_names.include?("id")
        raise "Method #{method} can only be used on Active Record models with an id column"
      end
    end
  end
end
