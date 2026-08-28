# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# Adds the ?where_exists= query parameter to a graphiti resource.
#
# ?where_exists=roles&filter[roles][type]=Group::BottomLayer::Leader restricts the records to those
# having at least one *readable* associated record matching the filters for that path (SQL EXISTS
# semantics), unlike ?include=, which only filters the sideload itself. Paths are dot-separated and
# may be combined with a comma, exactly like ?include=, and need not be included:
# ?where_exists=participations.roles&filter[participations.roles.type]=Event::Role::Leader
#
# Graphiti has no such parameter yet, see https://github.com/graphiti-api/graphiti/issues/430
module WhereExistsFilterable
  extend ActiveSupport::Concern

  class_methods do
    # Whether ?where_exists= can build a condition for this relationship. It needs an actual
    # database association, or a polymorphic group of them, to work with. The few relationships
    # without one, such as PersonResource#layer_group, are answered with a 400.
    def where_exists_supported?(association)
      sideload = sideload(association)
      return false unless sideload&.readable?
      return true if sideload.type == :polymorphic_belongs_to
      return false unless model.respond_to?(:reflect_on_association)

      reflection = model.reflect_on_association(association)
      !!reflection && !reflection.polymorphic?
    end
  end

  def build_scope(base, query, opts = {})
    param = where_exists_param(query)
    return super if param.blank?

    super(Api::WhereExists.new(self, query, param).apply(base), query, opts)
  end

  private

  def where_exists_param(query)
    paths = query.params[:where_exists]
    return if paths.blank?

    directive = JSONAPI::IncludeDirective.new(paths).to_hash
    query.top_level? ? directive : where_exists_remainder(directive, query)
  end

  def where_exists_remainder(directive, query)
    position = query.parents.map(&:association_name).compact + [query.association_name].compact
    position.reduce(directive) { |hash, association| hash[association] || {} }
      .select { |association, _| self.class.where_exists_supported?(association) }
  end
end
