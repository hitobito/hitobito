# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Group::Mover < Struct.new(:group)

  def candidates
    @candidate ||= possible_candidates - [group, group.parent]
  end

  def perform(target)
    group.parent_id = target.id
    group.save
  end

  private

  def possible_candidates
    possible_groups.select { |candidate| matching_childgroup?(candidate) }
  end

  def possible_groups
    group.hierarchy.collect do |g|
      g.self_and_siblings.without_deleted.order_by_type
    end.flatten
  end

  def matching_childgroup?(candidate)
    candidate.possible_children.include?(group.class)
  end

end
