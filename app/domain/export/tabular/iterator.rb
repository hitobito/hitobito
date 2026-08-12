# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of hitobito and licensed under the
#  Affero General Public License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.

module Export::Tabular
  # Custom Iterator to allow batching through ordered relation
  # noops if relation already has a limit defined
  class Iterator
    include Enumerable

    def initialize(list, batch_size)
      @list = list
      @batch_size = batch_size
    end

    def each(&block)
      return to_enum(:each) unless block_given?

      return list.each(&block) unless batchable?

      in_ordered_batches(block)
    end

    private

    attr_reader :list, :batch_size

    def in_ordered_batches(block)
      position = 0
      loop do
        batch = list.offset(position).limit(batch_size)

        batch.each(&block)

        position += batch_size
        break if batch.size < batch_size
      end
    end

    def batchable? = relation? && list.limit_value.nil?

    def relation? = list.is_a?(ActiveRecord::Relation)
  end
end
