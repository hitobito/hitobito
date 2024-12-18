# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of hitobito and licensed under the
#  Affero General Public License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.

module Export::Tabular
  # This does not support scopes with limit
  #
  # We use a custom iterator as find_each does not support custom ordering
  class Iterator
    def initialize(list, batch_size)
      @list = list
      @batch_size = batch_size
    end

    def each(&)
      return list.each(&) unless relation?

      in_ordered_batches(&)
    end

    private

    attr_reader :list, :batch_size

    def in_ordered_batches(&block)
      position = 0
      loop do
        batch = list.offset(position).limit(batch_size)
        batch.each(&block)
        position += batch_size
        break if batch.size < batch_size
      end
    end

    def relation? = list.is_a?(ActiveRecord::Relation)
  end
end
