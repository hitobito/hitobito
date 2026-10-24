# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# Builds the SQL EXISTS conditions behind the ?where_exists= query parameter.
# The directive is the parsed parameter as far as it applies to this resource,
# e.g. {participations: {roles: {}}}, and each of its levels contributes one condition.
class Api::WhereExists
  def initialize(resource, query, directive)
    @resource = resource
    @query = query
    @directive = directive
    @model = resource.model
  end

  # Narrows the scope to the records having at least one matching associated record, for every
  # relationship of the directive.
  def apply(scope)
    @directive.reduce(scope) do |restricted, (name, nested)|
      matching = matching(name, nested)
      restricted.where(@model.primary_key => matching)
    end
  end

  private

  # The records that have at least one matching associated record
  def matching(name, nested)
    sideload = sideload!(name)
    return polymorphic_matching(sideload, name, nested) if sideload.type == :polymorphic_belongs_to

    # Join and then key the condition on the association name,
    # so that self-referential associations work
    reflection = @model.reflect_on_association(name)
    @model.joins(name)
      .where(name => {reflection.klass.primary_key => related_scope(sideload, name, nested)})
  end

  # One condition per possible type, ORed. A group whose filters or nested paths do not apply to
  # it simply cannot match, but if that holds for every group, the request itself was wrong.
  def polymorphic_matching(sideload, name, nested)
    errors = []
    conditions = sideload.children.values.filter_map do |child|
      @model.where(sideload.grouper.field_name => child.group_name.to_s,
        child.foreign_key => related_scope(child, name, nested))
    rescue Graphiti::Errors::AttributeError, Graphiti::Errors::InvalidInclude => e
      errors << e
      nil
    end
    raise(errors.first || invalid_include(name)) if conditions.empty?

    conditions.reduce(:or)
  end

  # The sideload's readable records, narrowed by the filters and nested paths given for this one.
  def related_scope(sideload, name, nested)
    # replicate the query graphiti builds for included sideloads, so filter[...] means the same
    # thing regardless of whether the path is included. The empty include hash keeps this sub query
    # from mistaking the top level ?include= for its own.
    sub_query = Graphiti::Query.new(sideload.resource, @query.params, name, {},
      @query.parents + [@query], :all)
    # a sideload base_scope may restrict further, but never beyond what is readable
    base = sideload.resource.base_scope.merge(sideload.base_scope)
    scope = Graphiti::Scoping::Filter.new(sideload.resource, sub_query.hash, base).apply
    self.class.new(sideload.resource, sub_query, nested).apply(scope)
      .unscope(:select, :order, :limit, :offset)
  end

  def sideload!(name)
    raise invalid_include(name) unless @resource.class.where_exists_supported?(name)

    @resource.class.sideload(name)
  end

  def invalid_include(name)
    Graphiti::Errors::InvalidInclude.new(@resource, name)
  end
end
