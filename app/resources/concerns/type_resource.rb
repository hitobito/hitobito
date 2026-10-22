# frozen_string_literal: true

#  Copyright (c) 2026, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module TypeResource
  extend ActiveSupport::Concern

  class Type
    def initialize(type)
      @type = type
    end

    def id
      @type.sti_name
    end
  end

  included do
    self.adapter = Graphiti::Adapters::Null
    self.default_page_size = max_page_size

    with_options writable: false, filterable: false, sortable: false do
      attribute :id, :string, sortable: true
      attribute :label, :string, sortable: true
    end

    sort :id do |scope, direction|
      sort_types(scope, direction, &:id)
    end

    sort :label do |scope, direction|
      sort_types(scope, direction, &:label)
    end

    stat :total do
      count { |scope, _attr| scope.size }
    end

    paginate do |scope, current_page, per_page, _context, offset|
      scope[(current_page - 1) * per_page + offset.to_i, per_page] || []
    end
  end

  class_methods do
    def sideload_types(name, ids:, **options)
      has_many name, **options do
        scope { resource.base_scope }

        assign_each do |type, candidates|
          related_ids = type.public_send(ids)
          candidates.select { |candidate| related_ids.include?(candidate.id) }
        end
      end
    end
  end

  private

  def sort_types(types, direction, &key)
    sorted = types.sort_by(&key)
    (direction == :desc) ? sorted.reverse : sorted
  end
end
