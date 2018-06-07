# encoding: utf-8

#  Copyright (c) 2012-2018, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class EventFilter

  attr_reader :type, :filter, :group, :year, :sorting

  def initialize(type, filter, group, year, sorting)
    @type =type
    @filter = filter
    @group = group
    @year = year
    @sorting = sorting
  end

  def list_entries
    scope = Event. # nesting restricts to parent, we want more
      where(type: type).
      includes(:groups).
      with_group_id(relevant_group_ids).
      in_year(year).
      order_by_date.
      preload_all_dates.
      uniq

    sorting ? scope.reorder(sort_expression) : scope
  end

  private

  def relevant_group_ids
    case filter
    when 'layer' then [group.id] + descendants(layer: true).pluck(:id)
    else [group.id] + descendants.pluck(:id) # handles 'all' also
    end
  end

  def descendants(layer: false)
    scope = group.descendants
    layer ? scope.where(layer_group_id: group.layer_group_id) : scope
  end
end
